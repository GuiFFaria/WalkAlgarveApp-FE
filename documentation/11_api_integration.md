# API Integration

**Base URL:** Loaded from `.env` file via `flutter_dotenv`

---

## Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| POST | `/auth/login/` | No | Login |
| POST | `/auth/register/` | No | Register |
| POST | `/auth/token/refresh/` | No | Refresh JWT |
| GET | `/zones/` | No | All zones |
| GET | `/user/zones/` | Bearer | User-owned zones |
| GET | `/trails/?zone={id}` | Optional | Trails in a zone |
| POST | `/trails/` | Bearer | Toggle favorite |

---

## Token Handling

- Access token is cleaned before use (strips extra quotes/spaces)
- Sent as `Authorization: Bearer {token}` header
- On 401/403 responses, the app redirects to the login screen
