//
//  SongListModel.swift
//  MusicPlayer
//
//  Created by hb on 25/07/25.
//

import Foundation

struct MusicListModel : Codable {

    let headers : MusicListHeader?
    let results : [MusicListResult]?

    enum CodingKeys: String, CodingKey {
        case headers = "headers"
        case results = "results"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        headers = try values.decodeIfPresent(MusicListHeader.self, forKey: .headers)
        results = try values.decodeIfPresent([MusicListResult].self, forKey: .results)
    }
}

struct MusicListResult : Codable {
    
    func convertToSongs() -> Song {
        .init(
            id: id ?? UUID().uuidString,
            title: name ?? "",
            audioUrl: audio ?? "",
            audioImageUrl: albumImage ?? "",
            releasedate: releasedate ?? "",
            duration: duration ?? 0,
            downloadUrl: audiodownload ?? "",
            waveform: parseWaveform(from: waveform ?? "")
        )
    }

    let albumId : String?
    let albumImage : String?
    let albumName : String?
    let artistId : String?
    let artistIdstr : String?
    let artistName : String?
    let audio : String?
    let audiodownload : String?
    let audiodownloadAllowed : Bool?
    let duration : Int?
    let id : String?
    let image : String?
    let licenseCcurl : String?
    let name : String?
    let position : Int?
    let prourl : String?
    let releasedate : String?
    let shareurl : String?
    let shorturl : String?
    let waveform: String?

    func parseWaveform(from rawString: String) -> [Int] {
        // Remove extra escaping
        if let data = rawString.data(using: .utf8) {
            do {
                let waveformData = try JSONDecoder().decode(Waveform.self, from: data)
                return waveformData.peaks ?? []
            } catch {
                print("Error decoding waveform: \(error)")
            }
        }
        return []
    }
    

    enum CodingKeys: String, CodingKey {
        case albumId = "album_id"
        case albumImage = "album_image"
        case albumName = "album_name"
        case artistId = "artist_id"
        case artistIdstr = "artist_idstr"
        case artistName = "artist_name"
        case audio = "audio"
        case audiodownload = "audiodownload"
        case audiodownloadAllowed = "audiodownload_allowed"
        case duration = "duration"
        case id = "id"
        case image = "image"
        case licenseCcurl = "license_ccurl"
        case name = "name"
        case position = "position"
        case prourl = "prourl"
        case releasedate = "releasedate"
        case shareurl = "shareurl"
        case shorturl = "shorturl"
        case waveform = "waveform"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        albumId = try values.decodeIfPresent(String.self, forKey: .albumId)
        albumImage = try values.decodeIfPresent(String.self, forKey: .albumImage)
        albumName = try values.decodeIfPresent(String.self, forKey: .albumName)
        artistId = try values.decodeIfPresent(String.self, forKey: .artistId)
        artistIdstr = try values.decodeIfPresent(String.self, forKey: .artistIdstr)
        artistName = try values.decodeIfPresent(String.self, forKey: .artistName)
        audio = try values.decodeIfPresent(String.self, forKey: .audio)
        audiodownload = try values.decodeIfPresent(String.self, forKey: .audiodownload)
        audiodownloadAllowed = try values.decodeIfPresent(Bool.self, forKey: .audiodownloadAllowed)
        duration = try values.decodeIfPresent(Int.self, forKey: .duration)
        id = try values.decodeIfPresent(String.self, forKey: .id)
        image = try values.decodeIfPresent(String.self, forKey: .image)
        licenseCcurl = try values.decodeIfPresent(String.self, forKey: .licenseCcurl)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        position = try values.decodeIfPresent(Int.self, forKey: .position)
        prourl = try values.decodeIfPresent(String.self, forKey: .prourl)
        releasedate = try values.decodeIfPresent(String.self, forKey: .releasedate)
        shareurl = try values.decodeIfPresent(String.self, forKey: .shareurl)
        shorturl = try values.decodeIfPresent(String.self, forKey: .shorturl)
        waveform = try values.decodeIfPresent(String.self, forKey: .waveform)
    }
}

struct MusicListHeader : Codable {
    let code : Int?
    let errorMessage : String?
    let next : String?
    let resultsCount : Int?
    let resultsFullCount: Int?
    let status : String?
    let warnings : String?

    enum CodingKeys: String, CodingKey {
        case code = "code"
        case errorMessage = "error_message"
        case next = "next"
        case resultsCount = "results_count"
        case status = "status"
        case warnings = "warnings"
        case resultsFullCount = "results_fullcount"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        code = try values.decodeIfPresent(Int.self, forKey: .code)
        errorMessage = try values.decodeIfPresent(String.self, forKey: .errorMessage)
        next = try values.decodeIfPresent(String.self, forKey: .next)
        resultsCount = try values.decodeIfPresent(Int.self, forKey: .resultsCount)
        status = try values.decodeIfPresent(String.self, forKey: .status)
        warnings = try values.decodeIfPresent(String.self, forKey: .warnings)
        resultsFullCount = try values.decodeIfPresent(Int.self, forKey: .resultsFullCount)
    }
}

struct Waveform: Codable {
    let peaks: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case peaks = "peaks"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        peaks = try values.decodeIfPresent([Int].self, forKey: .peaks)
    }
}

/// - DUMMY JSON VALUES
/*
 {
   "headers": {
     "status": "success",
     "code": 0,
     "error_message": "",
     "warnings": "",
     "results_count": 10,
     "next": "https://api.jamendo.com/v3.0/tracks?client_id=2cd75770&format=json&limit=10&offset=10"
   },
   "results": [
     {
       "id": "168",
       "name": "J'm'e FPM",
       "duration": 183,
       "artist_id": "7",
       "artist_name": "TriFace",
       "artist_idstr": "triface",
       "album_name": "Premiers Jets",
       "album_id": "24",
       "license_ccurl": "",
       "position": 1,
       "releasedate": "2004-12-17",
       "album_image": "https://usercontent.jamendo.com?type=album&id=24&width=300&trackid=168",
       "audio": "https://prod-1.storage.jamendo.com/?trackid=168&format=mp31&from=Z%2F5x4znnVgQyOSuTOqXBbA%3D%3D%7CVUa9ZnWV7McNtgSOx8Ixzw%3D%3D",
       "audiodownload": "https://prod-1.storage.jamendo.com/download/track/168/mp32/",
       "prourl": "",
       "shorturl": "https://jamen.do/t/168",
       "shareurl": "https://www.jamendo.com/track/168",
       "audiodownload_allowed": true,
       "image": "https://usercontent.jamendo.com?type=album&id=24&width=300&trackid=168"
     },
     {
       "id": "169",
       "name": "Trio HxC",
       "duration": 101,
       "artist_id": "7",
       "artist_name": "TriFace",
       "artist_idstr": "triface",
       "album_name": "Premiers Jets",
       "album_id": "24",
       "license_ccurl": "",
       "position": 2,
       "releasedate": "2004-12-17",
       "album_image": "https://usercontent.jamendo.com?type=album&id=24&width=300&trackid=169",
       "audio": "https://prod-1.storage.jamendo.com/?trackid=169&format=mp31&from=bWsauF8%2FWQL8elk%2BoBmcQw%3D%3D%7CxsJiOIWzE%2BwnixVIKs73Lg%3D%3D",
       "audiodownload": "https://prod-1.storage.jamendo.com/download/track/169/mp32/",
       "prourl": "",
       "shorturl": "https://jamen.do/t/169",
       "shareurl": "https://www.jamendo.com/track/169",
       "audiodownload_allowed": true,
       "image": "https://usercontent.jamendo.com?type=album&id=24&width=300&trackid=169"
     },
     {
       "id": "170",
       "name": "Un Poil De Relifion",
       "duration": 207,
       "artist_id": "7",
       "artist_name": "TriFace",
       "artist_idstr": "triface",
       "album_name": "Premiers Jets",
       "album_id": "24",
       "license_ccurl": "",
       "position": 3,
       "releasedate": "2004-12-17",
       "album_image": "https://usercontent.jamendo.com?type=album&id=24&width=300&trackid=170",
       "audio": "https://prod-1.storage.jamendo.com/?trackid=170&format=mp31&from=mgPZ86yylkskt3wHBEK2WQ%3D%3D%7C6ve5K3yGd3qc8EMGcNNvWA%3D%3D",
       "audiodownload": "https://prod-1.storage.jamendo.com/download/track/170/mp32/",
       "prourl": "",
       "shorturl": "https://jamen.do/t/170",
       "shareurl": "https://www.jamendo.com/track/170",
       "audiodownload_allowed": true,
       "image": "https://usercontent.jamendo.com?type=album&id=24&width=300&trackid=170"
     },
     {
       "id": "171",
       "name": "Apologies",
       "duration": 145,
       "artist_id": "7",
       "artist_name": "TriFace",
       "artist_idstr": "triface",
       "album_name": "Premiers Jets",
       "album_id": "24",
       "license_ccurl": "",
       "position": 4,
       "releasedate": "2004-12-17",
       "album_image": "https://usercontent.jamendo.com?type=album&id=24&width=300&trackid=171",
       "audio": "https://prod-1.storage.jamendo.com/?trackid=171&format=mp31&from=xOlSPWplvwU976p9y30vUw%3D%3D%7ChlJuyxYf7OoAjL%2B3kTXDag%3D%3D",
       "audiodownload": "https://prod-1.storage.jamendo.com/download/track/171/mp32/",
       "prourl": "",
       "shorturl": "https://jamen.do/t/171",
       "shareurl": "https://www.jamendo.com/track/171",
       "audiodownload_allowed": true,
       "image": "https://usercontent.jamendo.com?type=album&id=24&width=300&trackid=171"
     },
     {
       "id": "172",
       "name": "Je Vomis Comme Je Chante",
       "duration": 177,
       "artist_id": "7",
       "artist_name": "TriFace",
       "artist_idstr": "triface",
       "album_name": "Premiers Jets",
       "album_id": "24",
       "license_ccurl": "",
       "position": 5,
       "releasedate": "2004-12-17",
       "album_image": "https://usercontent.jamendo.com?type=album&id=24&width=300&trackid=172",
       "audio": "https://prod-1.storage.jamendo.com/?trackid=172&format=mp31&from=MJvMBzgTiaFfgaIUrHKYBg%3D%3D%7Ccyl3EckoptFYgsg2KDk3Qw%3D%3D",
       "audiodownload": "https://prod-1.storage.jamendo.com/download/track/172/mp32/",
       "prourl": "",
       "shorturl": "https://jamen.do/t/172",
       "shareurl": "https://www.jamendo.com/track/172",
       "audiodownload_allowed": true,
       "image": "https://usercontent.jamendo.com?type=album&id=24&width=300&trackid=172"
     },
     {
       "id": "174",
       "name": "Mind Asylum",
       "duration": 183,
       "artist_id": "9",
       "artist_name": "Skaut",
       "artist_idstr": "skaut",
       "album_name": "Mind Asylum",
       "album_id": "25",
       "license_ccurl": "",
       "position": 1,
       "releasedate": "2004-12-18",
       "album_image": "https://usercontent.jamendo.com?type=album&id=25&width=300&trackid=174",
       "audio": "https://prod-1.storage.jamendo.com/?trackid=174&format=mp31&from=i4f%2Fp7qit1b7nM74FMPyIA%3D%3D%7Cd0ojLiqD6ZA7Ru38DJT86w%3D%3D",
       "audiodownload": "https://prod-1.storage.jamendo.com/download/track/174/mp32/",
       "prourl": "",
       "shorturl": "https://jamen.do/t/174",
       "shareurl": "https://www.jamendo.com/track/174",
       "audiodownload_allowed": true,
       "image": "https://usercontent.jamendo.com?type=album&id=25&width=300&trackid=174"
     },
     {
       "id": "175",
       "name": "You Don't Know",
       "duration": 322,
       "artist_id": "9",
       "artist_name": "Skaut",
       "artist_idstr": "skaut",
       "album_name": "Mind Asylum",
       "album_id": "25",
       "license_ccurl": "",
       "position": 2,
       "releasedate": "2004-12-18",
       "album_image": "https://usercontent.jamendo.com?type=album&id=25&width=300&trackid=175",
       "audio": "https://prod-1.storage.jamendo.com/?trackid=175&format=mp31&from=U%2FVN6Eq63Ld%2BbeNE5q9RPg%3D%3D%7CR820xxbPO3vxXhDNHMhMcA%3D%3D",
       "audiodownload": "https://prod-1.storage.jamendo.com/download/track/175/mp32/",
       "prourl": "",
       "shorturl": "https://jamen.do/t/175",
       "shareurl": "https://www.jamendo.com/track/175",
       "audiodownload_allowed": true,
       "image": "https://usercontent.jamendo.com?type=album&id=25&width=300&trackid=175"
     },
     {
       "id": "176",
       "name": "Overcome",
       "duration": 292,
       "artist_id": "9",
       "artist_name": "Skaut",
       "artist_idstr": "skaut",
       "album_name": "Mind Asylum",
       "album_id": "25",
       "license_ccurl": "",
       "position": 3,
       "releasedate": "2004-12-18",
       "album_image": "https://usercontent.jamendo.com?type=album&id=25&width=300&trackid=176",
       "audio": "https://prod-1.storage.jamendo.com/?trackid=176&format=mp31&from=Yjqwj3QQ%2Fl9kpbN1PdEkOw%3D%3D%7CHrSaCiFM7nSdLFIuHyCCDQ%3D%3D",
       "audiodownload": "https://prod-1.storage.jamendo.com/download/track/176/mp32/",
       "prourl": "",
       "shorturl": "https://jamen.do/t/176",
       "shareurl": "https://www.jamendo.com/track/176",
       "audiodownload_allowed": true,
       "image": "https://usercontent.jamendo.com?type=album&id=25&width=300&trackid=176"
     },
     {
       "id": "198",
       "name": "Trois Saucisses Dans Une Bulle",
       "duration": 33,
       "artist_id": "7",
       "artist_name": "TriFace",
       "artist_idstr": "triface",
       "album_name": "3 Saucisses Dans Une Bulle",
       "album_id": "28",
       "license_ccurl": "",
       "position": 1,
       "releasedate": "2004-12-21",
       "album_image": "https://usercontent.jamendo.com?type=album&id=28&width=300&trackid=198",
       "audio": "https://prod-1.storage.jamendo.com/?trackid=198&format=mp31&from=VVa4ADi6g75vZJfs%2B5bMew%3D%3D%7CaEBd%2BRNhz7QqyL4cEC7izQ%3D%3D",
       "audiodownload": "https://prod-1.storage.jamendo.com/download/track/198/mp32/",
       "prourl": "",
       "shorturl": "https://jamen.do/t/198",
       "shareurl": "https://www.jamendo.com/track/198",
       "audiodownload_allowed": true,
       "image": "https://usercontent.jamendo.com?type=album&id=28&width=300&trackid=198"
     },
     {
       "id": "199",
       "name": "New Bitch",
       "duration": 171,
       "artist_id": "7",
       "artist_name": "TriFace",
       "artist_idstr": "triface",
       "album_name": "3 Saucisses Dans Une Bulle",
       "album_id": "28",
       "license_ccurl": "",
       "position": 2,
       "releasedate": "2004-12-21",
       "album_image": "https://usercontent.jamendo.com?type=album&id=28&width=300&trackid=199",
       "audio": "https://prod-1.storage.jamendo.com/?trackid=199&format=mp31&from=GGSenAmuGCqaGtMXDWWjEQ%3D%3D%7CypEULBY6NfzJYRm%2FZOj0XA%3D%3D",
       "audiodownload": "https://prod-1.storage.jamendo.com/download/track/199/mp32/",
       "prourl": "",
       "shorturl": "https://jamen.do/t/199",
       "shareurl": "https://www.jamendo.com/track/199",
       "audiodownload_allowed": true,
       "image": "https://usercontent.jamendo.com?type=album&id=28&width=300&trackid=199"
     }
   ]
 }
 */
