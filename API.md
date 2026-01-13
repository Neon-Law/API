# Neon Law Matters API Documentation

## Overview

The Matters API provides access to legal matter repositories for authenticated Neon Law attorneys. Each matter
corresponds to an AWS CodeCommit repository containing case files, contracts, and legal documents managed through the
Sagebrush Standards system.

**Base URL:** `https://api.neonlaw.com`

## Authentication

All API requests require OIDC (OpenID Connect) authentication via Bearer token in the Authorization header. Obtain an access token from the Neon Law identity provider and include it in all requests.

**OIDC Configuration:**

- **Issuer:** `https://auth.neonlaw.com`
- **Authorization Endpoint:** `https://auth.neonlaw.com/oauth2/authorize`
- **Token Endpoint:** `https://auth.neonlaw.com/oauth2/token`
- **UserInfo Endpoint:** `https://auth.neonlaw.com/oauth2/userInfo`

**Example Request:**

```bash
# Exchange authorization code for access token (after user login)
TOKEN=$(curl -s -X POST https://auth.neonlaw.com/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=${AUTHORIZATION_CODE}" \
  -d "redirect_uri=${REDIRECT_URI}" \
  -d "client_id=${CLIENT_ID}" \
  -d "code_verifier=${CODE_VERIFIER}" | jq -r '.access_token')

# Use token to access API
curl -H "Authorization: Bearer $TOKEN" https://api.neonlaw.com/matters
```

## Endpoints

### GET /matters

Returns a list of all matters (CodeCommit repositories) accessible to the authenticated user.

**Response 200 - Success**

```json
{
  "matters": [
    {
      "name": "SmithVJones",
      "gitUrl": "https://git-codecommit.us-west-2.amazonaws.com/v1/repos/SmithVJones"
    },
    {
      "name": "AcmeCorp-Formation",
      "gitUrl": "https://git-codecommit.us-west-2.amazonaws.com/v1/repos/AcmeCorp-Formation"
    },
    {
      "name": "JohnsonEstate",
      "gitUrl": "https://git-codecommit.us-west-2.amazonaws.com/v1/repos/JohnsonEstate"
    }
  ]
}
```

**Response 401 - Unauthorized**

```json
{
  "error": {
    "code": "unauthorized",
    "message": "Authentication required"
  }
}
```

**Response 403 - Forbidden**

```json
{
  "error": {
    "code": "forbidden",
    "message": "Insufficient permissions to access matters"
  }
}
```

## Data Models

### Matter Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Matter name (CodeCommit repository name). Max 100 characters, alphanumeric + dash + underscore only. |
| `gitUrl` | string (uri) | Yes | Standard Git HTTPS URL for cloning. Format: `https://git-codecommit.<region>.amazonaws.com/v1/repos/<name>` |

### Error Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `code` | string | Yes | Machine-readable error code: `unauthorized`, `forbidden`, or `internal_error` |
| `message` | string | Yes | Human-readable error message |

## CodeCommit Repository Details

### URL Format

All matter repositories use the AWS CodeCommit HTTPS URL format:

```
https://git-codecommit.us-west-2.amazonaws.com/v1/repos/{MatterName}
```

### Repository Naming Rules

Matter names must comply with CodeCommit naming conventions:

- Maximum 100 characters
- Only alphanumeric characters, dashes (-), and underscores (_)
- Cannot end with `.git`
- Case sensitive
- Must be unique within the AWS account (account 731099197338)

### Cloning Repositories

All authentication uses OIDC tokens. The same OIDC token from `auth.neonlaw.com` is used for both the Matters API and CodeCommit Git operations via AWS STS web identity federation.

**Prerequisites:**

1. Install `git-remote-codecommit`: `pip install git-remote-codecommit`
2. Configure AWS profile with OIDC token (see setup instructions below)

```bash
# Clone a single matter using git-remote-codecommit with OIDC profile
git clone codecommit://neonlaw@SmithVJones ~/Standards/SmithVJones

# Clone all matters from API
curl -H "Authorization: Bearer $TOKEN" https://api.neonlaw.com/matters | \
  jq -r '.matters[] | "git clone codecommit://neonlaw@\(.name) ~/Standards/\(.name)"' | \
  bash
```

**AWS Profile Configuration (`~/.aws/config`):**

```ini
[profile neonlaw]
role_arn = arn:aws:iam::731099197338:role/NeonLawCodeCommitAccess
web_identity_token_file = ~/.neonlaw/token
role_session_name = neonlaw-user
```

The OIDC token is exchanged for temporary AWS credentials via `AssumeRoleWithWebIdentity`, eliminating the need for IAM user credentials.

## Integration with Setup Script

The `~/.standards/setup.sh` script uses this API to automatically clone all accessible matters:

1. Checks for OIDC access token in environment variable `NEON_LAW_TOKEN`
2. If token not found, prompts user to visit `https://auth.neonlaw.com/login`
3. Saves OIDC token to `~/.neonlaw/token` for git-remote-codecommit
4. Configures AWS profile for web identity federation if not already set
5. Calls `/matters` endpoint with Bearer token
6. Parses JSON response and clones each repository to `~/Standards/` using git-remote-codecommit
7. Falls back to hardcoded repository list if API unavailable

**Required Setup:**

- `NEON_LAW_TOKEN` - OIDC access token from `auth.neonlaw.com`
- `git-remote-codecommit` installed (`pip install git-remote-codecommit`)
- AWS profile configured for web identity federation (auto-configured by setup script)

## OpenAPI Specification

```yaml
openapi: 3.0.3
info:
  title: Neon Law Matters API
  description: API for retrieving matter repositories for authenticated attorneys
  version: 1.0.0
  contact:
    name: Neon Law
    url: https://neonlaw.com

servers:
  - url: https://api.neonlaw.com
    description: Production API

paths:
  /matters:
    get:
      summary: Get matters list
      description: |
        Returns a list of all matters (CodeCommit repositories) that the
        authenticated user has access to. Each matter includes the matter
        name and corresponding Git repository URL for cloning.
      operationId: getMatters
      tags:
        - Matters
      security:
        - bearerAuth: []
      responses:
        '200':
          description: Successfully retrieved matters list
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/MattersResponse'
              examples:
                multipleMatters:
                  summary: User with multiple matters
                  value:
                    matters:
                      - name: SmithVJones
                        gitUrl: https://git-codecommit.us-west-2.amazonaws.com/v1/repos/SmithVJones
                      - name: AcmeCorp-Formation
                        gitUrl: https://git-codecommit.us-west-2.amazonaws.com/v1/repos/AcmeCorp-Formation
                      - name: JohnsonEstate
                        gitUrl: https://git-codecommit.us-west-2.amazonaws.com/v1/repos/JohnsonEstate
                noMatters:
                  summary: User with no matters
                  value:
                    matters: []
        '401':
          description: Unauthorized - Authentication required
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              example:
                error:
                  code: unauthorized
                  message: Authentication required
        '403':
          description: Forbidden - User does not have permission
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              example:
                error:
                  code: forbidden
                  message: Insufficient permissions to access matters
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              example:
                error:
                  code: internal_error
                  message: An unexpected error occurred

components:
  schemas:
    MattersResponse:
      type: object
      required:
        - matters
      properties:
        matters:
          type: array
          description: List of matters accessible to the authenticated user
          items:
            $ref: '#/components/schemas/Matter'

    Matter:
      type: object
      required:
        - name
        - gitUrl
      properties:
        name:
          type: string
          description: |
            The matter name, which corresponds to the CodeCommit repository name.
            Must be unique within the AWS account and follow CodeCommit naming
            conventions (max 100 characters, alphanumeric, dash, underscore only).
          pattern: '[\w\.-]+'
          maxLength: 100
          example: SmithVJones
        gitUrl:
          type: string
          format: uri
          description: |
            Standard Git HTTPS URL for cloning the CodeCommit repository.
            Format: https://git-codecommit.<region>.amazonaws.com/v1/repos/<name>
          pattern: '^https://git-codecommit\.[a-z0-9-]+\.amazonaws\.com/v1/repos/[\w\.-]+$'
          example: https://git-codecommit.us-west-2.amazonaws.com/v1/repos/SmithVJones

    ErrorResponse:
      type: object
      required:
        - error
      properties:
        error:
          type: object
          required:
            - code
            - message
          properties:
            code:
              type: string
              description: Machine-readable error code
              enum:
                - unauthorized
                - forbidden
                - internal_error
              example: unauthorized
            message:
              type: string
              description: Human-readable error message
              example: Authentication required

  securitySchemes:
    bearerAuth:
      type: openIdConnect
      openIdConnectUrl: https://auth.neonlaw.com/.well-known/openid-configuration
      description: |
        OIDC authentication via Neon Law identity provider. Obtain an access token
        through the OAuth 2.0 Authorization Code flow with PKCE and include it as
        a Bearer token in the Authorization header. Token must have 'matters:read'
        scope to access matter repositories.

tags:
  - name: Matters
    description: Operations related to legal matters and their repositories
```

## References

- [AWS CodeCommit Repository Creation](https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-create-repository.html)
- [AWS CodeCommit Connection Methods](https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-connect.html)
- [AWS CodeCommit Regions and Endpoints](https://docs.aws.amazon.com/codecommit/latest/userguide/regions.html)
