from pwdlib import PasswordHash

# Argon2 (pwdlib's recommended hasher), as in the current FastAPI docs.
# The course used passlib + bcrypt; passlib is unmaintained.
password_hash = PasswordHash.recommended()


def hash_password(password: str) -> str:
    return password_hash.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return password_hash.verify(plain_password, hashed_password)
