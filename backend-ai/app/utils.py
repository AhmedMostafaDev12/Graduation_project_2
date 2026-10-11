import hashlib
import secrets

from pwdlib import PasswordHash

# Argon2 (pwdlib's recommended hasher), as in the current FastAPI docs.
# The course used passlib + bcrypt; passlib is unmaintained.
password_hash = PasswordHash.recommended()

# Verifying against this when the email doesn't exist takes the same time as a real check,
# so response timing doesn't reveal which emails have accounts.
_DUMMY_HASH = password_hash.hash("timing-equaliser")


def hash_password(password: str) -> str:
    return password_hash.hash(password)


def verify_password(plain_password: str, hashed_password: str | None) -> bool:
    if hashed_password is None:
        password_hash.verify(plain_password, _DUMMY_HASH)
        return False
    return password_hash.verify(plain_password, hashed_password)


def new_token() -> str:
    """A random secret for refresh and device tokens (no dots, so it can't look like a JWT)."""
    return secrets.token_urlsafe(32)


def hash_token(token: str) -> str:
    """Refresh and device tokens are stored only as SHA-256 hashes."""
    return hashlib.sha256(token.encode()).hexdigest()
