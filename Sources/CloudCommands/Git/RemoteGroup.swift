import Vapor
import CloudAPI
import Globals

public struct RemoteGroup: CommandGroup {
    public struct Signature: CommandSignature { }
    public let signature = Signature()
    
    public let commands: Commands = [
        "set": RemoteSet(),
        "remove": RemoteRemove(),
    ]
    
    public let help: String? = "interacts with git remotes on vapor cloud."

    public init() {}

    /// See `CommandGroup`.
    public func run(using ctx: CommandContext<RemoteGroup>) throws {
        ctx.console.info("Interact with git remotes on Vapor Cloud.")
        ctx.console.output("Use `vapor cloud remote -h` to see commands.")
    }
}

struct RemoteRemove: Command {
    struct Signature: CommandSignature { }
    let signature = Signature()
    let help: String? = "unlink your local repository from a vapor cloud app."
    
    
    func run(using ctx: Context) throws {
        try checkGit()
        try Git.removeRemote(named: "cloud")
        ctx.console.output("removed cloud repository.")
    }

    func checkGit() throws {
        let isGit = Git.isGitRepository()
        guard isGit else {
            throw "not currently in a git repository."
        }

        let alreadyConfigured = try Git.isCloudConfigured()
        if !alreadyConfigured {
            throw "no cloud repository configured."
        }
    }
}

struct RemoteSet: Command {
    struct Signature: CommandSignature {
        let app: Option = .app
    }
    let signature = Signature()
    let help: String? = "link your local repo to a cloud app."

    /// See `Command`.
    func run(using ctx: Context) throws {
        try checkGit()

        let token = try Token.load()
        let access = CloudApp.Access(with: token)
        let apps = try access.list()
        let app = try ctx.select(from: apps)
        try Git.setRemote(named: "cloud", url: app.gitURL)
        ctx.console.output("cloud repository configured.")
        // TODO:
        // Load environments and push branches?
        ctx.console.pushEphemeral()
        let push = ctx.console.confirm("would you like to push to now?")
        ctx.console.popEphemeral()
        guard push else { return }
        
        ctx.console.pushEphemeral()
        ctx.console.output("pushing `master` to cloud...")
        try Git.pushCloud(branch: "master", force: false)
        ctx.console.popEphemeral()
        ctx.console.output("pushed `master` to cloud.")
//        return app.map { app in
//        }
        
//        let access = CloudApp.Access(with: token, on: ctx.container)
//        let apps = access.list()
//        let app = ctx.select(from: apps)
//        return app.map { app in
//            try Git.setRemote(named: "cloud", url: app.gitURL)
//            ctx.console.output("Cloud repository configured.")
//            // TODO:
//            // Load environments and push branches?
//            ctx.console.pushEphemeral()
//            let push = ctx.console.confirm("Would you like to push to now?")
//            ctx.console.popEphemeral()
//            guard push else { return }
//
//            ctx.console.pushEphemeral()
//            ctx.console.output("Pushing `master` to cloud...")
//            try Git.pushCloud(branch: "master", force: false)
//            ctx.console.popEphemeral()
//            ctx.console.output("Pushed `master` to cloud.")
//        }
    }

    func checkGit() throws {
        let isGit = Git.isGitRepository()
        guard isGit else {
            throw "Not currently in a git repository."
        }

        let alreadyConfigured = try Git.isCloudConfigured()
        guard alreadyConfigured else { return }

        var error = "Cloud is already configured."
        error += "\n"
        error += "Use 'vapor cloud remote remove' and try again."
        throw error
    }
}

extension CommandContext {
    func select(from apps: [CloudApp]) throws -> CloudApp {
        if apps.isEmpty { throw "No apps found, visit https://dashboard.vapor.cloud/apps to create one." }
        return self.console.choose("Which app?", from: apps) {
            return $0.name.consoleText()
        }
    }
    
    func select(from apps: EventLoopFuture<[CloudApp]>) -> EventLoopFuture<CloudApp> {
        todo()
//        return apps.map { apps in
//            if apps.isEmpty { throw "No apps found, visit https://dashboard.vapor.cloud/apps to create one." }
//            return self.console.choose("Which app?", from: apps) {
//                return $0.name.consoleText()
//            }
//        }
    }
}

