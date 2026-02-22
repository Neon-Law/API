import Configuration

let config = ConfigReader(provider: EnvironmentVariablesProvider())
let env = config.string(forKey: "ENV", default: "local")

if env == "production" || env == "staging" {
    try await APILambda.run()
} else {
    try await APILocalServer.run()
}
