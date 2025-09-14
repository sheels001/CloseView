import SwiftUI

struct User: Codable, Identifiable {
    let id: UUID
    var name: String
    var friendCode: String
}







struct Post: Codable, Identifiable {
    let id: UUID
    let authorID: UUID
    let text: String
    let createdAt: Date
}







@MainActor
class FOViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var posts: [Post] = []
    @Published var friends: [User] = []

    let backendURL = "http://127.0.0.1:8080"

    func createUser(name: String) async {
        guard let url = URL(string: "\(backendURL)/user") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["name": name])
        
        if let data = try? await URLSession.shared.data(for: request).0,
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
        }
    }

    func createPost(text: String) async {
        guard let user = currentUser,
              let url = URL(string: "\(backendURL)/post") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["authorID": user.id.uuidString, "text": text])
        _ = try? await URLSession.shared.data(for: request)
    }





  
    func fetchFeed() async {
        guard let user = currentUser,
              let url = URL(string: "\(backendURL)/feed/\(user.id.uuidString)") else { return }
        if let data = try? await URLSession.shared.data(from: url).0,
           let posts = try? JSONDecoder().decode([Post].self, from: data) {
            self.posts = posts
        }
    }
}







struct ContentView: View {
    @StateObject var vm = FOViewModel()
    @State private var newText = ""

    var body: some View {
        VStack {
            HStack {
                TextField("What's new?", text: $newText)
                Button("Post") {
                    Task {
                        await vm.createPost(text: newText)
                        await vm.fetchFeed()
                        newText = ""
                    }
                }
            }.padding()

            List(vm.posts) { post in
                VStack(alignment: .leading) {
                    Text(post.text)
                    Text(post.createdAt, style: .time).font(.caption).foregroundColor(.gray)
                }
            }
        }
        .task {
            if vm.currentUser == nil {
                await vm.createUser(name: "You")
            }
            await vm.fetchFeed()
        }
    }
}

@main
struct FriendsOnlyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
