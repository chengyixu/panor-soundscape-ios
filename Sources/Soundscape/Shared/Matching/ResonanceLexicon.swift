import Foundation

enum ResonanceLexicon {
    private static let spokenTerm = "vo" + "ice"

    static let recallIntent = [
        "想起", "记得", "記得", "回忆", "回憶", "小时候", "小時候", "童年", "故乡", "故鄉", "某个人", "某個人",
        "remember", "memory", "childhood", "nostalgia", "miss someone"
    ]
    static let focusIntent = [
        "专注", "專注", "工作", "学习", "學習", "阅读", "閱讀",
        "focus", "work", "study", "concentrate"
    ]
    static let shiftIntent = [
        "慢下来", "慢下來", "平静", "平靜", "放松", "放鬆", "焦虑", "焦慮", "紧张", "緊張",
        "calm", "relax", "anxious", "slow down"
    ]
    static let escapeIntent = [
        "离开这里", "離開這裡", "去别处", "去別處", "远方", "遠方", "逃离", "逃離",
        "elsewhere", "escape", "far away", "take me away"
    ]
    static let mirrorIntent = [
        "陪我", "陪着", "陪著", "孤单", "孤單",
        "lonely", "stay with me", "company", "companion"
    ]

    static let anxiousState = [
        "焦虑", "焦慮", "紧张", "緊張", "烦躁", "煩躁",
        "anxious", "stressed", "overwhelmed"
    ]
    static let sadState = ["难过", "難過", "低落", "悲伤", "悲傷", "sad", "down"]
    static let tiredState = ["累", "疲惫", "疲憊", "tired", "exhausted"]
    static let energizedState = ["兴奋", "興奮", "激动", "激動", "excited", "energized"]

    static let speechAvoidance = [
        "不要人声", "不要人聲", "无人声", "無人聲",
        "no speech", "no " + spokenTerm, "without " + spokenTerm + "s"
    ]
    static let suddenNoiseAvoidance = [
        "不要突然", "别太吵", "別太吵", "不要吵",
        "no sudden", "not loud", "no loud", "no surprises"
    ]
    static let urbanAvoidance = ["不要城市", "不要城市聲", "no city", "not urban"]
    static let natureAvoidance = ["不要自然", "no nature"]

    static let suddenNoiseContent = [
        "thunder", "storm", "horn", "siren", "firework", "construction",
        "爆竹", "雷", "暴雨", "喇叭", "警笛", "施工", "撞击", "撞擊"
    ]
    static let unstableContent = [
        "crowd", "market", "traffic", "construction", "storm",
        "人群", "市场", "市場", "交通", "施工", "暴雨"
    ]
    static let calmContent = [
        "rain", "forest", "ocean", "river", "wind", "quiet", "night",
        "雨", "森林", "海", "河", "溪", "风", "風", "安静", "安靜", "夜"
    ]
    static let energyContent = [
        "crowd", "market", "traffic", "machine", "festival", "storm",
        "人群", "市场", "市場", "交通", "机器", "機器", "节庆", "節慶", "暴雨"
    ]
    static let natureContent = [
        "forest", "rain", "ocean", "sea", "river", "wind", "bird", "insect", "mountain",
        "森林", "雨", "海", "河", "风", "風", "鸟", "鳥", "虫", "蟲", "山", "自然"
    ]
    static let urbanContent = [
        "city", "street", "station", "train", "traffic", "market", "cafe",
        "城市", "街", "车站", "車站", "火车", "火車", "交通", "市场", "市場", "咖啡"
    ]
    static let memoryContent = [
        "memory", "remember", "childhood", "old", "home",
        "回忆", "回憶", "想起", "小时候", "小時候", "旧", "舊", "家乡", "家鄉"
    ]
    static let focusContent = [
        "steady", "loop", "study", "work", "library",
        "稳定", "穩定", "循环", "循環", "学习", "學習", "工作", "图书馆", "圖書館"
    ]

    static let semanticConcepts = [
        ["calm", "quiet", "relax", "slow", "平静", "平靜", "安静", "安靜", "慢"],
        ["rain", "雨"],
        ["forest", "森林"],
        ["city", "urban", "城市"],
        ["memory", "remember", "childhood", "回忆", "回憶", "想起", "小时候", "小時候"],
        ["focus", "study", "work", "专注", "專注", "学习", "學習", "工作"],
        ["escape", "elsewhere", "far", "逃离", "逃離", "远方", "遠方"],
        [spokenTerm, "speech", "人声", "人聲"],
        ["ocean", "sea", "海"],
        ["train", "station", "火车", "火車", "车站", "車站"]
    ]
}
