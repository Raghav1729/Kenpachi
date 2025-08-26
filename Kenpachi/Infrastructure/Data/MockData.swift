import Foundation
import Combine

struct MockData {
    static let sampleMovies: [Content] = [
        Content(
            id: "1",
            title: "Avatar: The Way of Water",
            overview: "Set more than a decade after the events of the first film, learn the story of the Sully family (Jake, Neytiri, and their kids), the trouble that follows them, the lengths they go to keep each other safe, the battles they fight to stay alive, and the tragedies they endure.",
            posterURL: "https://image.tmdb.org/t/p/w500/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/s16H6tpK2utvwDtzZ8Qy4qm5Emw.jpg",
            releaseDate: Date(),
            genres: [Genre(id: 1, name: "Action"), Genre(id: 2, name: "Adventure")],
            rating: 8.2,
            contentType: .movie
        ),
        Content(
            id: "2",
            title: "Black Panther: Wakanda Forever",
            overview: "Queen Ramonda, Shuri, M'Baku, Okoye and the Dora Milaje fight to protect their nation from intervening world powers in the wake of King T'Challa's death.",
            posterURL: "https://image.tmdb.org/t/p/w500/sv1xJUazXeYqALzczSZ3O6nkH75.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/xDMIl84Qo5Tsu62c9DGWhmPI67A.jpg",
            releaseDate: Date(),
            genres: [Genre(id: 1, name: "Action"), Genre(id: 3, name: "Drama")],
            rating: 7.8,
            contentType: .movie
        ),
        Content(
            id: "3",
            title: "Top Gun: Maverick",
            overview: "After more than thirty years of service as one of the Navy's top aviators, and dodging the advancement in rank that would ground him, Pete 'Maverick' Mitchell finds himself training a detachment of TOP GUN graduates for a specialized mission the likes of which no living pilot has ever seen.",
            posterURL: "https://image.tmdb.org/t/p/w500/62HCnUTziyWcpDaBO2i1DX17ljH.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/odJ4hx6g6vBt4lBWKFD1tI8WS4x.jpg",
            releaseDate: Date(),
            genres: [Genre(id: 1, name: "Action"), Genre(id: 4, name: "Thriller")],
            rating: 8.9,
            contentType: .movie
        )
    ]
    
    static let sampleTVShows: [Content] = [
        Content(
            id: "4",
            title: "House of the Dragon",
            overview: "The Targaryen dynasty is at the absolute apex of its power, with more than 15 dragons under their yoke. Most empires crumble from such heights. In the case of the Targaryens, their slow fall begins when King Viserys breaks with a century of tradition by naming his daughter Rhaenyra heir to the Iron Throne.",
            posterURL: "https://image.tmdb.org/t/p/w500/7QMsOTMUswlwxJP0rTTZfmz2tX2.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/1X4h40fcB4WWUmIBK0auT4zRBAV.jpg",
            releaseDate: Date(),
            genres: [Genre(id: 5, name: "Fantasy"), Genre(id: 3, name: "Drama")],
            rating: 8.5,
            contentType: .tvShow
        ),
        Content(
            id: "5",
            title: "The Rings of Power",
            overview: "Beginning in a time of relative peace, we follow an ensemble cast of characters as they confront the re-emergence of evil to Middle-earth.",
            posterURL: "https://image.tmdb.org/t/p/w500/mYLOqiStMxDK3fYZFirgrMt8z5d.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/1HdUgalQy4UNRA28mqUA0eHa2uj.jpg",
            releaseDate: Date(),
            genres: [Genre(id: 5, name: "Fantasy"), Genre(id: 2, name: "Adventure")],
            rating: 7.9,
            contentType: .tvShow
        ),
        Content(
            id: "6",
            title: "Stranger Things",
            overview: "When a young boy vanishes, a small town uncovers a mystery involving secret experiments, terrifying supernatural forces, and one strange little girl.",
            posterURL: "https://image.tmdb.org/t/p/w500/49WJfeN0moxb9IPfGn8AIqMGskD.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/56v2KjBlU4XaOv9rVYEQypROD7P.jpg",
            releaseDate: Date(),
            genres: [Genre(id: 6, name: "Sci-Fi"), Genre(id: 7, name: "Horror")],
            rating: 8.7,
            contentType: .tvShow
        )
    ]
    
    static let sampleAnime: [Content] = [
        Content(
            id: "7",
            title: "Attack on Titan",
            overview: "Many years ago, the last remnants of humanity were forced to retreat behind the towering walls of a fortified city to escape the massive, man-eating Titans that roamed the land outside their fortress.",
            posterURL: "https://image.tmdb.org/t/p/w500/hTP1DtLGFamjfu8WqjnuQdP1n4i.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/rqbCbjB19amtOtFQbb3K2lgm2zv.jpg",
            releaseDate: Date(),
            genres: [Genre(id: 8, name: "Anime"), Genre(id: 1, name: "Action")],
            rating: 9.0,
            contentType: .anime
        ),
        Content(
            id: "8",
            title: "Demon Slayer",
            overview: "It is the Taisho Period in Japan. Tanjiro, a kindhearted boy who sells charcoal for a living, finds his family slaughtered by a demon.",
            posterURL: "https://image.tmdb.org/t/p/w500/xUfRZu2mi8jH6SzQEJGP6tjBuYj.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/6tt3CFiTmIoC6rAdJGPoorYdWI8.jpg",
            releaseDate: Date(),
            genres: [Genre(id: 8, name: "Anime"), Genre(id: 1, name: "Action")],
            rating: 8.8,
            contentType: .anime
        )
    ]
    
    static func getContentSections() -> [ContentSectionData] {
        return [
            ContentSectionData(title: "Trending Movies", content: sampleMovies),
            ContentSectionData(title: "Popular TV Shows", content: sampleTVShows),
            ContentSectionData(title: "Top Anime", content: sampleAnime)
        ]
    }
    
    static func getHeroContent() -> Content {
        return Content(
            id: "hero_mandalorian",
            title: "The Mandalorian",
            overview: "After the fall of the Galactic Empire, lawlessness has spread throughout the galaxy. A lone gunfighter makes his way through the outer reaches, earning his keep as a bounty hunter.",
            posterURL: "https://image.tmdb.org/t/p/w500/sWgBv7LV2PRoQgkxwlibdGXKz1S.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/o7qi2v4uWQ8bZ1OcBCmyOGCGgzI.jpg",
            releaseDate: Date(),
            genres: [
                Genre(id: 1, name: "Sci-Fi"),
                Genre(id: 2, name: "Adventure"),
                Genre(id: 3, name: "Action")
            ],
            rating: 8.7,
            contentType: .tvShow
        )
    }
    
    static func getContinueWatching() -> [Content] {
        return [
            Content(
                id: "continue_1",
                title: "Loki",
                overview: "After stealing the Tesseract during the events of Avengers: Endgame, an alternate version of Loki is brought to the mysterious Time Variance Authority.",
                posterURL: "https://image.tmdb.org/t/p/w500/kEl2t3OhXc3Zb9FBh1AuYzRTgZp.jpg",
                backdropURL: "https://image.tmdb.org/t/p/w1280/kqjL17yufvn9OVLyXYpvtyrFfak.jpg",
                releaseDate: Date(),
                genres: [Genre(id: 1, name: "Action"), Genre(id: 2, name: "Adventure")],
                rating: 8.2,
                contentType: .tvShow
            ),
            Content(
                id: "continue_2",
                title: "Encanto",
                overview: "The tale of an extraordinary family, the Madrigals, who live hidden in the mountains of Colombia, in a magical house, in a vibrant town, in a wondrous, charmed place called an Encanto.",
                posterURL: "https://image.tmdb.org/t/p/w500/4j0PNHkMr5ax3IA8tjtxcmPU3QT.jpg",
                backdropURL: "https://image.tmdb.org/t/p/w1280/3G1Q5xF40HkUBJXxt2DQgQzKTp5.jpg",
                releaseDate: Date(),
                genres: [Genre(id: 1, name: "Animation"), Genre(id: 2, name: "Family")],
                rating: 7.2,
                contentType: .movie
            )
        ]
    }
}