"""CLIP's byte-level BPE tokenizer, read from a Hugging Face `tokenizer.json` (spec D34, D41).

Plain Python, so the server needs no extra library for MobileCLIP's text half. It follows the
file's own rules: NFC, whitespace collapsed, lower case; split into letter runs, single digits
and runs of other symbols; bytes mapped to printable characters (GPT-2's table); BPE with
`</w>` at the end of each word; start and end tokens around at most 77 tokens. A test checks
it against the reference tokenizer on sample texts.
"""

import itertools
import json
import re
import unicodedata
from functools import lru_cache
from pathlib import Path

CONTEXT = 77  # CLIP's text length, start and end tokens included
# [\p{L}]+ | [\p{N}] | [^\s\p{L}\p{N}]+ in Python's `re`: letters = word characters that are
# neither digits nor "_"; the third class keeps "_" (a symbol for CLIP)
_SPLIT = re.compile(r"'s|'t|'re|'ve|'m|'ll|'d|[^\W\d_]+|\d|(?:[^\s\w]|_)+")
_SPACES = re.compile(r"\s+")


@lru_cache(maxsize=1)
def _byte_table() -> dict[int, str]:
    """GPT-2's map from every byte to a printable character (byte-level BPE)."""
    printable = (
        list(range(ord("!"), ord("~") + 1))
        + list(range(ord("¡"), ord("¬") + 1))
        + list(range(ord("®"), ord("ÿ") + 1))
    )
    chars = list(printable)
    extra = 0
    for b in range(256):
        if b not in printable:
            printable.append(b)
            chars.append(256 + extra)
            extra += 1
    return {b: chr(c) for b, c in zip(printable, chars, strict=True)}


class ClipTokenizer:
    def __init__(self, path: str | Path):
        data = json.loads(Path(path).read_text(encoding="utf-8"))
        model = data["model"]
        self.vocab: dict[str, int] = model["vocab"]
        merges = [m.split(" ") if isinstance(m, str) else m for m in model["merges"]]
        self.ranks = {tuple(pair): i for i, pair in enumerate(merges)}
        self.suffix = model.get("end_of_word_suffix") or "</w>"
        self.unknown = self.vocab[model.get("unk_token") or "<|endoftext|>"]
        self.start = self.vocab["<|startoftext|>"]
        self.end = self.vocab["<|endoftext|>"]
        self._bpe_cache: dict[str, list[str]] = {}

    def _bpe(self, token: str) -> list[str]:
        if token in self._bpe_cache:
            return self._bpe_cache[token]
        word = list(token[:-1]) + [token[-1] + self.suffix]
        while len(word) > 1:
            pairs = [
                (self.ranks.get((a, b)), i)
                for i, (a, b) in enumerate(itertools.pairwise(word))
            ]
            ranked = [(r, i) for r, i in pairs if r is not None]
            if not ranked:
                break
            best = min(ranked)[0]
            merged, i = [], 0
            while i < len(word):
                if i < len(word) - 1 and self.ranks.get((word[i], word[i + 1])) == best:
                    merged.append(word[i] + word[i + 1])
                    i += 2
                else:
                    merged.append(word[i])
                    i += 1
            word = merged
        self._bpe_cache[token] = word
        return word

    def encode(self, text: str, length: int = CONTEXT) -> list[int]:
        """Token ids: start, the text's tokens (cut to fit), end."""
        text = _SPACES.sub(" ", unicodedata.normalize("NFC", text)).lower()
        table = _byte_table()
        ids: list[int] = []
        for piece in _SPLIT.findall(text):
            mapped = "".join(table[b] for b in piece.encode("utf-8"))
            ids.extend(self.vocab.get(t, self.unknown) for t in self._bpe(mapped))
        return [self.start, *ids[: length - 2], self.end]
