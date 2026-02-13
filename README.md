# NeonLaw API

Swift-based API for retrieving NeonLaw matter repositories from AWS CodeCommit.

## Overview

The NeonLaw API provides authenticated access to legal matter repositories stored in AWS CodeCommit for Neon Law attorneys. This implementation uses Swift OpenAPI Generator with Hummingbird 2.x for type-safe API development.

## Technology Stack

- **HTTP Server**: Hummingbird 2.x
- **API Specification**: OpenAPI 3.0.3
- **Code Generation**: Swift OpenAPI Generator
- **AWS Integration**: Soto (AWS SDK for Swift)
- **Testing**: Swift Testing framework

## Prerequisites

- Swift 6.0 or later
- macOS 15.0 or later
- AWS credentials configured (for accessing CodeCommit)

## AWS Configuration

The API requires AWS credentials to access CodeCommit repositories in the NeonLaw AWS account (731099197338). Configure your credentials using one of these methods:

### Environment Variables

```bash
export AWS_REGION=us-west-2
export AWS_ACCESS_KEY_ID=<your-access-key>
export AWS_SECRET_ACCESS_KEY=<your-secret-key>
```

### AWS Credentials File

```ini
# ~/.aws/credentials
[default]
aws_access_key_id = <your-access-key>
aws_secret_access_key = <your-secret-key>

# ~/.aws/config
[default]
region = us-west-2
```

## Building

```bash
swift build
```

## Running Tests

```bash
swift test
```

All tests use the Swift Testing framework. The test suite includes:

- **CodeCommitServiceTests**: Unit tests for AWS CodeCommit integration
- **MattersEndpointTests**: Integration tests for the API endpoints

## Running Locally

```bash
swift run API
```

The server will start on `http://127.0.0.1:8080`.

## API Endpoints

### GET /matters

Returns a list of all CodeCommit repositories (matters) accessible in the NeonLaw AWS account.

**Response 200**:

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
    }
  ]
}
```

**Response 500**:

```json
{
  "error": {
    "code": "internal_error",
    "message": "An unexpected error occurred"
  }
}
```

## Testing the API

```bash
# Start the server
swift run API

# In another terminal, test the endpoint
curl http://127.0.0.1:8080/matters
```

## Code Formatting

This project follows the Trifecta Swift formatting standards:

```bash
# Format code
swift format -i -r .

# Check formatting
swift format lint --strict --recursive --parallel --no-color-diagnostics .
```

## Project Structure

```
Sources/API/
├── main.swift                      # Entry point and Hummingbird setup
├── openapi.yaml                    # OpenAPI specification
├── openapi-generator-config.yaml   # Generator configuration
└── Services/
    └── CodeCommitService.swift     # AWS CodeCommit integration

Tests/APITests/
├── MattersEndpointTests.swift      # Integration tests
└── CodeCommitServiceTests.swift    # Unit tests
```

## Authentication

**Note**: Authentication is not yet implemented in this initial version. All requests are currently unauthenticated. OIDC authentication will be added in a future iteration.

## Future Enhancements

- [ ] OIDC authentication via AWS Cognito
- [ ] JWT validation for API requests
- [ ] Role-based access control
- [ ] Additional endpoints for matter details
- [ ] Deployment to AWS Lambda or ECS

## Development

### Adding New Endpoints

1. Update `openapi.yaml` with the new endpoint specification
2. Implement the handler in `main.swift` (APIImpl struct)
3. Add integration tests in `Tests/APITests/`
4. Run tests: `swift test`
5. Format code: `swift format -i -r .`

### Generated Code

The Swift OpenAPI Generator plugin automatically generates:

- `Types.swift` - Request/response models
- `Server.swift` - Server protocol and handlers

These files are generated during build and should not be manually edited.

## License

See [LICENSE](LICENSE) for details.
