// main.swift
import Vapor

struct User: Content, Identifiable {
    let id: UUID
    var name: String
    let friendCode: String
    var friends: [UUID] = []
}

struct Post: Content, Identifiable {
    let id: UUID
    let authorID: UUID
    var text: String
    let createdAt: Date
}

var users: [UUID: User] = [:]
var posts: [UUID: Post] = [:]

func generateFriendCode() -> String {
    let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    return String((0..<6).map { _ in alphabet.randomElement()! })
}

let app = Application(.development)
defer { app.shutdown() }

app.post("user") { req -> User in
    let data = try req.content.decode([String: String].self)
    let name = data["name"] ?? "Anonymous"
    let user = User(id: UUID(), name: name, friendCode: generateFriendCode())
    users[user.id] = user
    return user
}
app.post("friend") { req -> User in
    let data = try req.content.decode([String: String].self)
    guard let fromIDStr = data["fromID"], let fromID = UUID(uuidString: fromIDStr),
          let code = data["code"] else { throw Abort(.badRequest) }
    
    guard let friend = users.values.first(where: { $0.friendCode == code }) else {
        throw Abort(.notFound, reason: "Friend code not found")
    }
    
    users[fromID]?.friends.append(friend.id)
    users[friend.id]?.friends.append(fromID)
    
    return friend
}
app.get("feed", ":userID") { req -> [Post] in
    guard let userIDStr = req.parameters.get("userID"),
          let userID = UUID(uuidString: userIDStr),
          let user = users[userID] else { throw Abort(.notFound) }
    
    let feedPosts = posts.values.filter { user.friends.contains($0.authorID) || $0.authorID == userID }
    return feedPosts.sorted { $0.createdAt > $1.createdAt }
}
app.post("post") { req -> Post in
    let data = try req.content.decode([String: String].self)
    guard let authorIDStr = data["authorID"], let authorID = UUID(uuidString: authorIDStr),
          let text = data["text"] else { throw Abort(.badRequest) }
    
    let post = Post(id: UUID(), authorID: authorID, text: text, createdAt: Date())
    posts[post.id] = post
    return post
}
try app.run()
