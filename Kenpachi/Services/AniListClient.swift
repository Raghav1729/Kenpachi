//
//  AniListClient.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

// Kenpachi/Services/AniListClient.swift

import Foundation
import ComposableArchitecture // To extend DependencyValues for TCA

// MARK: - AniList API Client Interface

struct AniListAPIClient {
    // Anime methods
    var fetchAnime: @Sendable (_ category: AniListCategory, _ page: Int) async throws -> AniListPage<AniListMedia>
    var fetchAnimeDetails: @Sendable (_ id: Int) async throws -> AniListAnimeDetails

    // Manga methods
    var fetchManga: @Sendable (_ category: AniListCategory, _ page: Int) async throws -> AniListPage<AniListMedia>
    var fetchMangaDetails: @Sendable (_ id: Int) async throws -> AniListMangaDetails

    // Search methods
    var searchAnime: @Sendable (_ query: String, _ page: Int) async throws -> AniListPage<AniListMedia>
    var searchManga: @Sendable (_ query: String, _ page: Int) async throws -> AniListPage<AniListMedia>
}

// MARK: - Live AniList API Client Implementation

extension AniListAPIClient: DependencyKey {
    static let liveValue = Self(
        fetchAnime: { category, page in
            let query = GraphQLQuery(query: category.query, variables: GraphQLQuery.convertVariables(category.variables))
            let networkService = NetworkService()
            let response: AniListDataWrapper<AniListPageWrapper<AniListMedia>> = try await networkService.postRequest(
                url: URL(string: Constants.aniListGraphQLURL)!,
                body: query
            )
            guard let pageData = response.data?.page else {
                throw NetworkError.decodingError(
                    NSError(domain: "AniListClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AniList anime page response or data is nil."])
                )
            }
            return pageData
        },
        fetchAnimeDetails: { id in
            let query = GraphQLQuery(query: AniListCategory.animeDetails(id: id).query, variables: GraphQLQuery.convertVariables(AniListCategory.animeDetails(id: id).variables))
            let networkService = NetworkService()
            // AniList GraphQL returns a single Media object directly under `data.Media` for detail queries
            struct MediaResponse: Decodable, Equatable { // Helper struct to match `data.Media` path
                let Media: AniListAnimeDetails?
            }
            let response: AniListDataWrapper<MediaResponse> = try await networkService.postRequest(
                url: URL(string: Constants.aniListGraphQLURL)!,
                body: query
            )
            guard let details = response.data?.Media else {
                throw NetworkError.decodingError(
                    NSError(domain: "AniListClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AniList anime details response or data is nil."])
                )
            }
            return details
        },
        fetchManga: { category, page in
            let query = GraphQLQuery(query: category.query, variables: GraphQLQuery.convertVariables(category.variables))
            let networkService = NetworkService()
            let response: AniListDataWrapper<AniListPageWrapper<AniListMedia>> = try await networkService.postRequest(
                url: URL(string: Constants.aniListGraphQLURL)!,
                body: query
            )
            guard let pageData = response.data?.page else {
                throw NetworkError.decodingError(
                    NSError(domain: "AniListClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AniList manga page response or data is nil."])
                )
            }
            return pageData
        },
        fetchMangaDetails: { id in
            let query = GraphQLQuery(query: AniListCategory.mangaDetails(id: id).query, variables: GraphQLQuery.convertVariables(AniListCategory.mangaDetails(id: id).variables))
            let networkService = NetworkService()
            // Helper struct to match `data.Media` path
            struct MediaResponse: Decodable, Equatable {
                let Media: AniListMangaDetails?
            }
            let response: AniListDataWrapper<MediaResponse> = try await networkService.postRequest(
                url: URL(string: Constants.aniListGraphQLURL)!,
                body: query
            )
            guard let details = response.data?.Media else {
                throw NetworkError.decodingError(
                    NSError(domain: "AniListClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AniList manga details response or data is nil."])
                )
            }
            return details
        },
        searchAnime: { query, page in
            let gqlQuery = AniListCategory.searchAnime(query: query, page: page)
            let graphQLQuery = GraphQLQuery(query: gqlQuery.query, variables: GraphQLQuery.convertVariables(gqlQuery.variables))
            let networkService = NetworkService()
            let response: AniListDataWrapper<AniListPageWrapper<AniListMedia>> = try await networkService.postRequest(
                url: URL(string: Constants.aniListGraphQLURL)!,
                body: graphQLQuery
            )
            guard let pageData = response.data?.page else {
                throw NetworkError.decodingError(
                    NSError(domain: "AniListClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AniList search anime response or data is nil."])
                )
            }
            return pageData
        },
        searchManga: { query, page in
            let gqlQuery = AniListCategory.searchManga(query: query, page: page)
            let graphQLQuery = GraphQLQuery(query: gqlQuery.query, variables: GraphQLQuery.convertVariables(gqlQuery.variables))
            let networkService = NetworkService()
            let response: AniListDataWrapper<AniListPageWrapper<AniListMedia>> = try await networkService.postRequest(
                url: URL(string: Constants.aniListGraphQLURL)!,
                body: graphQLQuery
            )
            guard let pageData = response.data?.page else {
                throw NetworkError.decodingError(
                    NSError(domain: "AniListClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AniList search manga response or data is nil."])
                )
            }
            return pageData
        }
    )

    // MARK: - Mock AniList API Client Implementation (for testing and previews)

    static let testValue = Self(
        fetchAnime: { category, page in
            return AniListPage(pageInfo: AniListPageInfo(total: 2, perPage: 20, currentPage: page, lastPage: 1, hasNextPage: false),
                               media: [
                                   AniListMedia(id: 1001, title: AniListTitle(romaji: "Mock Anime 1", english: "Mock Anime 1", native: "モックアニメ1"), coverImage: AniListCoverImage(extraLarge: "https://via.placeholder.com/150", large: "https://via.placeholder.com/150", medium: nil, color: nil), startDate: nil, description: "Description 1", type: .anime, averageScore: 85, genres: ["Action", "Adventure"]),
                                   AniListMedia(id: 1002, title: AniListTitle(romaji: "Mock Anime 2", english: "Mock Anime 2", native: "モックアニメ2"), coverImage: AniListCoverImage(extraLarge: "https://via.placeholder.com/150", large: "https://via.placeholder.com/150", medium: nil, color: nil), startDate: nil, description: "Description 2", type: .anime, averageScore: 90, genres: ["Fantasy", "Magic"])
                               ])
        },
        fetchAnimeDetails: { id in
            return AniListAnimeDetails(id: id, title: AniListTitle(romaji: "Mock Anime Detail \(id)", english: "Mock Anime Detail \(id)", native: "モックアニメ詳細\(id)"), description: "Detailed description for mock anime \(id).", coverImage: AniListCoverImage(extraLarge: "https://via.placeholder.com/300", large: "https://via.placeholder.com/300", medium: nil, color: nil), bannerImage: "https://via.placeholder.com/600x300", startDate: AniListFuzzyDate(year: 2020, month: 1, day: 1), endDate: AniListFuzzyDate(year: 2020, month: 3, day: 25), episodes: 12, duration: 24, season: .winter, seasonYear: 2020, status: .finished, averageScore: 88, genres: ["Action", "Sci-Fi"], tags: nil, externalLinks: nil, format: .tv, type: .anime)
        },
        fetchManga: { category, page in
            return AniListPage(pageInfo: AniListPageInfo(total: 2, perPage: 20, currentPage: page, lastPage: 1, hasNextPage: false),
                               media: [
                                   AniListMedia(id: 2001, title: AniListTitle(romaji: "Mock Manga 1", english: "Mock Manga 1", native: "モック漫画1"), coverImage: AniListCoverImage(extraLarge: "https://via.placeholder.com/150", large: "https://via.placeholder.com/150", medium: nil, color: nil), startDate: nil, description: "Manga Description 1", type: .manga, averageScore: 88, genres: ["Adventure", "Comedy"]),
                                   AniListMedia(id: 2002, title: AniListTitle(romaji: "Mock Manga 2", english: "Mock Manga 2", native: "モック漫画2"), coverImage: AniListCoverImage(extraLarge: "https://via.placeholder.com/150", large: "https://via.placeholder.com/150", medium: nil, color: nil), startDate: nil, description: "Manga Description 2", type: .manga, averageScore: 92, genres: ["Romance", "Drama"])
                               ])
        },
        fetchMangaDetails: { id in
            return AniListMangaDetails(id: id, title: AniListTitle(romaji: "Mock Manga Detail \(id)", english: "Mock Manga Detail \(id)", native: "モック漫画詳細\(id)"), description: "Detailed description for mock manga \(id).", coverImage: AniListCoverImage(extraLarge: "https://via.placeholder.com/300", large: "https://via.placeholder.com/300", medium: nil, color: nil), bannerImage: "https://via.placeholder.com/600x300", startDate: AniListFuzzyDate(year: 2018, month: 5, day: 10), endDate: AniListFuzzyDate(year: 2021, month: 1, day: 30), chapters: 200, volumes: 20, status: .finished, averageScore: 90, genres: ["Action", "Fantasy"], tags: nil, externalLinks: nil, format: .manga, type: .manga)
        },
        searchAnime: { query, page in
            return AniListPage(pageInfo: AniListPageInfo(total: 1, perPage: 20, currentPage: page, lastPage: 1, hasNextPage: false),
                               media: [
                                   AniListMedia(id: 1003, title: AniListTitle(romaji: "Search Result Anime \(query)", english: "Search Result Anime \(query)", native: "検索アニメ\(query)"), coverImage: AniListCoverImage(extraLarge: "https://via.placeholder.com/150", large: "https://via.placeholder.com/150", medium: nil, color: nil), startDate: nil, description: "Anime matching '\(query)'", type: .anime, averageScore: 80, genres: ["Mystery"])
                               ])
        },
        searchManga: { query, page in
            return AniListPage(pageInfo: AniListPageInfo(total: 1, perPage: 20, currentPage: page, lastPage: 1, hasNextPage: false),
                               media: [
                                   AniListMedia(id: 2003, title: AniListTitle(romaji: "Search Result Manga \(query)", english: "Search Result Manga \(query)", native: "検索漫画\(query)"), coverImage: AniListCoverImage(extraLarge: "https://via.placeholder.com/150", large: "https://via.placeholder.com/150", medium: nil, color: nil), startDate: nil, description: "Manga matching '\(query)'", type: .manga, averageScore: 75, genres: ["Slice of Life"])
                               ])
        }
    )

    static func previewValue(anime: [AniListMedia] = [], manga: [AniListMedia] = []) -> Self {
        Self(
            fetchAnime: { _, page in
                AniListPage(pageInfo: AniListPageInfo(total: anime.count, perPage: 20, currentPage: page, lastPage: 1, hasNextPage: false), media: anime)
            },
            fetchAnimeDetails: { id in
                try await AniListAPIClient.testValue.fetchAnimeDetails(id)
            },
            fetchManga: { _, page in
                AniListPage(pageInfo: AniListPageInfo(total: manga.count, perPage: 20, currentPage: page, lastPage: 1, hasNextPage: false), media: manga)
            },
            fetchMangaDetails: { id in
                try await AniListAPIClient.testValue.fetchMangaDetails(id)
            },
            searchAnime: { query, page in
                try await AniListAPIClient.testValue.searchAnime(query, page)
            },
            searchManga: { query, page in
                try await AniListAPIClient.testValue.searchManga(query, page)
            }
        )
    }
}

// MARK: - Dependency Values Extension

extension DependencyValues {
    var aniListAPIClient: AniListAPIClient {
        get { self[AniListAPIClient.self] }
        set { self[AniListAPIClient.self] = newValue }
    }
}
