import SwiftUI

struct Drama: Identifiable, Codable {
    let id: Int
    let title: String
    let cat: String
    let hot: Double
    let eps: Int
    let desc: String
    let tags: [String]
    let video: String
    let c1: String   // 封面渐变色起
    let c2: String   // 封面渐变色止

    var gradient: LinearGradient {
        LinearGradient(colors: [Color(hex: c1), Color(hex: c2)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

let sampleDramas: [Drama] = [
    .init(id: 1, title: "离婚后，我成了他高攀不起的白月光", cat: "逆袭", hot: 412.6, eps: 88,
          desc: "三年婚姻她低到尘埃，离婚当天摇身一变成集团继承人。前夫跪求复合？晚了。",
          tags: ["都市", "逆袭", "爽文"],
          video: "https://media.w3.org/2010/05/sintel/trailer.mp4",
          c1: "3B1D5A", c2: "FF6A3D"),
    .init(id: 2, title: "战神归来：龙王的女婿", cat: "逆袭", hot: 398.2, eps: 96,
          desc: "他是不败战神，却甘愿入赘三年受尽白眼。一朝身份曝光，全城权贵连夜来拜。",
          tags: ["都市", "战神", "打脸"],
          video: "https://media.w3.org/2010/05/bunny/trailer.mp4",
          c1: "123A5C", c2: "4FD1C5"),
    .init(id: 3, title: "闪婚老公竟是隐藏首富", cat: "甜宠", hot: 386.4, eps: 72,
          desc: "被退婚当天她随便拉了个路人闪婚，没想到这位「路人」是全城最不敢惹的男人。",
          tags: ["甜宠", "闪婚", "豪门"],
          video: "https://media.w3.org/2010/05/video/movie_300.mp4",
          c1: "4A1C2E", c2: "F5A623"),
    .init(id: 4, title: "重生之我把渣男虐哭了", cat: "重生", hot: 355.1, eps: 80,
          desc: "前世她为渣男倾家荡产含恨而终，重生回到订婚前夜，这一次她要亲手改写结局。",
          tags: ["重生", "复仇", "爽文"],
          video: "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4",
          c1: "1F2A44", c2: "C084FC"),
    .init(id: 5, title: "神探外卖员：每一单都是凶案", cat: "悬疑", hot: 342.8, eps: 64,
          desc: "普通外卖小哥意外卷入连环命案，每送一单，就离真凶更近一步……",
          tags: ["悬疑", "刑侦", "反转"],
          video: "https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4",
          c1: "3D2B1F", c2: "E6B980"),
    .init(id: 6, title: "大明小厨娘：御膳房升职记", cat: "古装", hot: 328.0, eps: 76,
          desc: "现代米其林主厨穿越大明朝，从洗菜丫头一路杀进御膳房，连皇帝都点名要她做菜。",
          tags: ["古装", "美食", "轻喜"],
          video: "https://media.w3.org/2010/05/sintel/trailer.mp4",
          c1: "0F3D2E", c2: "7BE0A2"),
    .init(id: 7, title: "天降萌宝：总裁爹地请签收", cat: "甜宠", hot: 315.5, eps: 68,
          desc: "五年前不告而别，五年后她带着天才龙凤胎回国，两个小家伙主动给妈咪找对象。",
          tags: ["萌宝", "甜宠", "追妻"],
          video: "https://media.w3.org/2010/05/bunny/trailer.mp4",
          c1: "2A1A3A", c2: "E07AB8"),
    .init(id: 8, title: "末世囤货：我在安全屋躺赢", cat: "脑洞", hot: 301.9, eps: 60,
          desc: "末世降临前一个月她开始疯狂囤货，当所有人挣扎求生，她已在安全屋里吃火锅。",
          tags: ["末世", "脑洞", "生存"],
          video: "https://media.w3.org/2010/05/video/movie_300.mp4",
          c1: "333333", c2: "99AABB"),
    .init(id: 9, title: "窗台上的她总在午夜消失", cat: "悬疑", hot: 289.3, eps: 52,
          desc: "对面楼的女孩每到午夜就凭空消失，他用望远镜记录了三十个夜晚，终于看到那一幕……",
          tags: ["悬疑", "惊悚", "烧脑"],
          video: "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4",
          c1: "5C1F1F", c2: "FFB36A"),
    .init(id: 10, title: "赘婿觉醒：我岳父是大佬", cat: "都市", hot: 276.7, eps: 84,
          desc: "人人嘲笑的窝囊赘婿，实则身怀绝技。岳父的对手步步紧逼，是时候亮出真身了。",
          tags: ["赘婿", "都市", "打脸"],
          video: "https://media.w3.org/2010/05/sintel/trailer.mp4",
          c1: "1A2A5C", c2: "6AB0FF")
]
