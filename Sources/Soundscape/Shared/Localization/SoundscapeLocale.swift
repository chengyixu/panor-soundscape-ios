import Foundation

enum SoundscapeLocale: CaseIterable, Sendable {
    // MARK: - Tab bar
    case tabExplore
    case tabMap
    case tabContribute
    case tabMe
    case tabExploreSubtitle
    case tabRankingsSubtitle

    // MARK: - Explore
    case exploreTitle
    case exploreEyebrow
    case exploreDetail
    case exploreSearchPlaceholder
    case exploreSearchAuthor
    case exploreSearchLocation
    case exploreSearchAll
    case exploreDurationAny
    case exploreDurationUnder1min
    case exploreDuration1to5min
    case exploreDurationOver5min
    case exploreLoading
    case exploreEmpty
    case exploreEmptyTitle
    case exploreLoadingFailed
    case exploreBy
    case explorePopularSearches
    case exploreRecentSearches
    case exploreClear
    case exploreClearSearch
    case exploreDeleteSearch
    case exploreLatestRecordings
    case exploreNoResultsTitle
    case exploreNoResultsDetail
    case exploreTopResults
    case exploreRecordings
    case explorePlayRecording
    case exploreFacetCategory
    case exploreFacetRecording
    case exploreFacetDuration

    // MARK: - Map
    case mapEyebrow
    case mapTitle
    case mapDetail
    case mapLoading
    case mapEmpty
    case mapEmptyTitle
    case mapShowAll
    case mapSelectedRecording
    case mapPlayThis
    case mapRecording

    // MARK: - Rankings
    case rankingsEyebrow
    case rankingsTitle
    case rankingsDetail
    case rankingsStillForming
    case rankingsPlayAndSaveHelp
    case rankingsNatureParks
    case rankingsUrbanAmbience
    case rankingsMarketsCafes
    case rankingsLoading
    case rankingsFailed
    case rankingsLaneSuffix

    // MARK: - Player
    case playerSelectTrack
    case playerDetails
    case playerRecordingDetails
    case playerAuthor
    case playerLocation
    case playerDuration
    case playerCategory
    case playerRecordedAt
    case playerMadeForYou
    case playerFromExplore
    case playerFromMap
    case playerFromRankings
    case playerYourRecording
    case playerLoading
    case playerNeedleParked
    case playerNeedleOnRecord
    case playerTurntable
    case playerSave
    case playerUnsave
    case playerOpenDetailsHint
    case playerSelectedTrack
    case playerNeedle
    case playerNeedlePaused
    case playerNeedlePlaying
    case playerNeedleGestureHint
    case playerPause
    case playerPlay
    case playerOpenPlayer
    case playerClosePlayer
    case playerFeedbackTitle
    case playerFeedbackDetail
    case playerResonates
    case playerNotNow
    case playerLessLikeThis

    // MARK: - Create
    case createEyebrow
    case createTitle
    case createDetail
    case createRecordingDuration
    case createImportAudio
    case createLocationSection
    case createTitleAndDescription
    case createTitleField
    case createTitlePlaceholder
    case createDescriptionField
    case createDescriptionPlaceholder
    case createThinkingGeneratingTitle
    case createCoverSection
    case createAIGeneratingCover
    case createAICoverHint
    case createChooseFromLibrary
    case createRegenerate
    case createCategoryAndFeel
    case createCategoryLabel
    case createCategoryPlace
    case createCategoryNature
    case createCategoryArchitecture
    case createPersonalToSocial
    case createPersonal
    case createSocial
    case createMemoryToPresent
    case createMemory
    case createPresent
    case createPublicToggle
    case createLoginToPublish
    case createPublishing
    case createPublishSoundscape
    case createPublished
    case createRecordAnother
    case createLocating
    case createCurrentLocation
    case createNoLocationPermission
    case createThinking
    case createRecordingState
    case createRequestingPermission
    case createReadyToRecord
    case createCannotReadCover
    case createSelectAudioFile
    case createCannotReadAudio
    case createDefaultPrompt
    case createListeningForMetadata

    // MARK: - Identity
    case identityLogin
    case identityRegister
    case identityRegisterTitle
    case identityEmail
    case identityUsername
    case identityPassword
    case identityLoginButton
    case identityRegisterButton
    case identitySwitchToRegister
    case identitySwitchToLogin
    case identityLoggedInAs
    case identityLogout
    case identityNeedLogin
    case identityLoginOrRegister
    case identityEyebrow
    case identityTitle
    case identityDetail
    case identityOrContinueWith
    case identityGoogleSignIn
    case identityAppleSignIn

    // MARK: - Library / My
    case libraryEyebrow
    case libraryTitle
    case libraryDetail
    case libraryLoading
    case libraryEmpty
    case libraryMyRecordings
    case librarySaved
    case libraryMakePublic
    case libraryMakePrivate
    case libraryDelete
    case libraryDeleteConfirm
    case libraryCancel
    case librarySavedEmpty
    case libraryMyEmpty
    case libraryForYou
    case libraryClose
    case libraryForYouEntrySubtitle
    case libraryAccountMenu
    case librarySignedOutTitle
    case librarySignedOutDetail
    case librarySignInOrRegister
    case libraryReadingRecordings
    case libraryNoRecordingsTitle
    case libraryNoRecordingsDetail
    case libraryPlayFeaturedRecording
    case libraryFilterRecordings
    case libraryFilterPublic
    case libraryFilterPrivate
    case settingsSectionAccount
    case settingsSectionPrivacy
    case settingsSectionGeneral
    case settingsSectionForYou
    case settingsTitle
    case settingsAccount
    case settingsPrivacyPolicy
    case settingsTermsOfService
    case settingsAppVersion
    case settingsLogout
    case settingsLogoutConfirm
    case settingsLanguage
    case settingsLanguageSystem
    case settingsPrivacyBody
    case settingsTermsBody
    case settingsResetRecommendations
    case settingsResetRecommendationsConfirm
    case settingsResetRecommendationsDone
    case libraryYourSoundArchive
    case libraryPrivateUntilSignIn
    case librarySoundRecorder
    case libraryMyRecordingsHeader
    case libraryPublicLabel
    case libraryPrivateLabel

    // MARK: - Errors / Shared
    case errorCannotPlay
    case errorNoAudio
    case errorAudioDeviceDisconnected
    case errorNetworkFailed
    case errorTryAgain
    case errorInvalidImage
    case errorCannotProcessImage
    case errorInvalidURL
    case errorInvalidParams
    case errorServerFailed
    case errorSelectM4A
    case errorCoverEmpty
    case errorAudioEmpty
    case errorAudioTooLarge
    case errorCoverTooLarge
    case errorTitleRequired
    case errorTitleTooLong
    case errorDescriptionTooLong
    case errorLocationNameTooLong
    case errorLoginRequired
    case errorNetworkUnavailable
    case errorTitleGenerationFailed
    case errorCoverGenerationFailed
    case errorServerDataUnrecognized
    case errorKeychainFailed
    case errorAccountCreatedButCantSave
    case errorAudioPlaybackUnavailable
    case errorMicPermission
    case errorRecordingFailed
    case errorLocationUnavailable
    case errorLocationUnavailableCanPublish
    case errorNoPlayableReady
    case errorPersonalizationUnavailable
    case errorUsernameRequired
    case errorPasswordTooShort
    case errorEmailRequired
    case errorGeneric

    // MARK: - ForYou
    case forYouEyebrow
    case forYouTitle
    case forYouDetail
    case forYouPrivateByDefault
    case forYouAnySound
    case forYouCannotAutoPlay
    case forYouListeningShaping
    case forYouAnythingPlaceholder
    case forYouPrivateInput
    case forYouMakeSoundscape
    case forYouGuideMe
    case forYouGuidedQuestion
    case forYouGuidedPlaceholder
    case forYouMakeNow
    case forYouMicrophoneTitle
    case forYouMicrophoneDetail
    case forYouRecord
    case forYouStop

    // MARK: - General
    case generalOK
    case generalCancel
    case generalRetry
    case generalLoading
    case generalBack
    case generalContinue
    case generalNotNow
    case generalDone
    case generalDismiss
    case generalPrimaryNavigation

    // MARK: - AppShell tab labels
    case appShellExplore
    case appShellMap
    case appShellContribute
    case appShellMe

    // MARK: - Miscellaneous UI
    case coverLoadFailed
    case coverNoCover
    case coverAILabel
    case coverAIBadge
    case coverLoading
    case unnamedSoundscape
    case unknownLocation
    case soundscapeUnit
    case charactersUnit

    func localized(for locale: AppLocale) -> String {
        switch locale {
        case .zhHans: zhHans
        case .en: en
        case .zhHant: zhHant
        }
    }

    private var zhHans: String {
        switch self {
        case .tabExplore: "探索"
        case .tabMap: "地图"
        case .tabContribute: "发布"
        case .tabMe: "我的"
        case .tabExploreSubtitle: "发现"
        case .tabRankingsSubtitle: "榜单"
        case .exploreTitle: "探索身边的声景"
        case .exploreEyebrow: "发现录音"
        case .exploreDetail: "每段录音都来自真实环境；搜索地点或作者，也可以按时长筛选。"
        case .exploreSearchPlaceholder: "搜索声景"
        case .exploreSearchAuthor: "作者"
        case .exploreSearchLocation: "地点"
        case .exploreSearchAll: "全部"
        case .exploreDurationAny: "任意时长"
        case .exploreDurationUnder1min: "1 分钟以内"
        case .exploreDuration1to5min: "1–5 分钟"
        case .exploreDurationOver5min: "5 分钟以上"
        case .exploreLoading: "正在读取声景列表"
        case .exploreEmpty: "还没有公开声景，发布第一条吧。"
        case .exploreEmptyTitle: "这里还很安静"
        case .exploreLoadingFailed: "声景列表加载失败"
        case .exploreBy: "按条件探索"
        case .explorePopularSearches: "热门搜索"
        case .exploreRecentSearches: "最近搜索"
        case .exploreClear: "清除"
        case .exploreClearSearch: "清除搜索"
        case .exploreDeleteSearch: "删除搜索"
        case .exploreLatestRecordings: "最新录音"
        case .exploreNoResultsTitle: "没有匹配的声音"
        case .exploreNoResultsDetail: "换一个真实地点、作者、类别或标题试试。"
        case .exploreTopResults: "最相关结果"
        case .exploreRecordings: "录音"
        case .explorePlayRecording: "播放"
        case .exploreFacetCategory: "类别"
        case .exploreFacetRecording: "声音"
        case .exploreFacetDuration: "时长"
        case .mapEyebrow: "声音地图"
        case .mapTitle: "声音落在地图上"
        case .mapDetail: "每个黑点都是一段真实录音；选择地点即可查看作者并开始播放。"
        case .mapLoading: "正在读取录音坐标"
        case .mapEmpty: "还没有地图声景，带位置发布的录音会出现在这里。"
        case .mapEmptyTitle: "地图上还没有录音"
        case .mapShowAll: "显示全部录音地点"
        case .mapSelectedRecording: "已选录音"
        case .mapPlayThis: "播放这段录音"
        case .mapRecording: "地图录音"
        case .rankingsEyebrow: "社区精选"
        case .rankingsTitle: "最多播放的声景"
        case .rankingsDetail: "大家都喜欢的声音。"
        case .rankingsStillForming: "榜单还在形成，播放和收藏会让真实声景逐渐排出顺序。"
        case .rankingsPlayAndSaveHelp: "播放和收藏会让真实声景逐渐排出顺序。"
        case .rankingsNatureParks: "自然公园"
        case .rankingsUrbanAmbience: "城市氛围"
        case .rankingsMarketsCafes: "市场与咖啡馆"
        case .rankingsLoading: "正在加载排行"
        case .rankingsFailed: "排行加载失败"
        case .rankingsLaneSuffix: "排行"
        case .playerSelectTrack: "选择声音"
        case .playerDetails: "详情"
        case .playerRecordingDetails: "录音详情"
        case .playerAuthor: "作者"
        case .playerLocation: "地点"
        case .playerDuration: "时长"
        case .playerCategory: "分类"
        case .playerRecordedAt: "录制时间"
        case .playerMadeForYou: "为你推荐"
        case .playerFromExplore: "来自探索"
        case .playerFromMap: "来自地图"
        case .playerFromRankings: "来自榜单"
        case .playerYourRecording: "你的录音"
        case .playerLoading: "正在加载"
        case .playerNeedleParked: "唱针已移出"
        case .playerNeedleOnRecord: "唱针位于唱片上"
        case .playerTurntable: "唱片机播放器"
        case .playerSave: "收藏"
        case .playerUnsave: "取消收藏"
        case .playerOpenDetailsHint: "打开声音详情"
        case .playerSelectedTrack: "已选择"
        case .playerNeedle: "唱针"
        case .playerNeedlePaused: "唱片外，已暂停"
        case .playerNeedlePlaying: "唱片上，播放中"
        case .playerNeedleGestureHint: "左右拖动控制播放；上下拖动选择声音"
        case .playerPause: "暂停"
        case .playerPlay: "播放"
        case .playerOpenPlayer: "打开播放器"
        case .playerClosePlayer: "关闭播放器"
        case .playerFeedbackTitle: "这段声音适合你吗？"
        case .playerFeedbackDetail: "反馈会优先调整当前会话，再缓慢更新长期偏好。"
        case .playerResonates: "有共鸣"
        case .playerNotNow: "不是现在"
        case .playerLessLikeThis: "少推荐这类"
        case .createEyebrow: "公开发布"
        case .createTitle: "发布声景"
        case .createDetail: "录音、导入、AI 增强之后公开发布，让你的声音出现在探索页面和地图上。"
        case .createRecordingDuration: "录音时长"
        case .createImportAudio: "从文件导入音频"
        case .createLocationSection: "地点"
        case .createTitleAndDescription: "标题和描述"
        case .createTitleField: "标题"
        case .createTitlePlaceholder: "给这段声音起个名字"
        case .createDescriptionField: "描述"
        case .createDescriptionPlaceholder: "一句话描述"
        case .createThinkingGeneratingTitle: "思考中，正在生成标题和描述"
        case .createCoverSection: "封面"
        case .createAIGeneratingCover: "AI 正在自动生成封面"
        case .createAICoverHint: "AI 封面会自动生成；也可以上传自己的封面覆盖它。"
        case .createChooseFromLibrary: "从相册选择"
        case .createRegenerate: "重新自动生成"
        case .createCategoryAndFeel: "分类和感受"
        case .createCategoryLabel: "分类"
        case .createCategoryPlace: "地方"
        case .createCategoryNature: "自然"
        case .createCategoryArchitecture: "建筑"
        case .createPersonalToSocial: "个人到社群"
        case .createPersonal: "个人"
        case .createSocial: "社群"
        case .createMemoryToPresent: "记忆到当下"
        case .createMemory: "记忆"
        case .createPresent: "当下"
        case .createPublicToggle: "公开到探索与地图"
        case .createLoginToPublish: "登录后发布"
        case .createPublishing: "正在发布"
        case .createPublishSoundscape: "发布声景"
        case .createPublished: "已发布"
        case .createRecordAnother: "再录一段"
        case .createLocating: "正在获取当前位置…"
        case .createCurrentLocation: "当前位置"
        case .createNoLocationPermission: "未获得位置权限，将不带位置发布"
        case .createThinking: "思考中"
        case .createRecordingState: "录音中，再按一次结束"
        case .createRequestingPermission: "正在请求麦克风权限"
        case .createReadyToRecord: "按下录音键开始捕捉"
        case .createCannotReadCover: "无法读取所选封面。"
        case .createSelectAudioFile: "请选择一个音频文件。"
        case .createCannotReadAudio: "无法读取所选音频文件。"
        case .createDefaultPrompt: "录下一段让你想停下脚步的声音"
        case .createListeningForMetadata: "AI 正在听取地点与录音提示…"
        case .identityLogin: "登录"
        case .identityRegister: "注册"
        case .identityRegisterTitle: "注册"
        case .identityEmail: "邮箱"
        case .identityUsername: "姓名（选填）"
        case .identityPassword: "密码"
        case .identityLoginButton: "登录"
        case .identityRegisterButton: "注册"
        case .identitySwitchToRegister: "没有账号？去注册"
        case .identitySwitchToLogin: "已有账号？去登录"
        case .identityLoggedInAs: "已登录"
        case .identityLogout: "退出登录"
        case .identityNeedLogin: "需要登录"
        case .identityLoginOrRegister: "登录或注册"
        case .identityEyebrow: "Soundscape 账号"
        case .identityTitle: "保存你的声音档案"
        case .identityDetail: "登录后可以发布、收藏，并管理公开或私密的录音。"
        case .identityOrContinueWith: "或"
        case .identityGoogleSignIn: "使用 Google 登录"
        case .identityAppleSignIn: "使用 Apple 登录"
        case .libraryEyebrow: "你的声音档案"
        case .libraryTitle: "你的录音与收藏"
        case .libraryDetail: "管理你创建或收藏的声景。"
        case .libraryLoading: "正在加载你的档案"
        case .libraryEmpty: "你还没有录音或收藏。"
        case .libraryMyRecordings: "我的录音"
        case .librarySaved: "已收藏"
        case .libraryMakePublic: "设为公开"
        case .libraryMakePrivate: "设为私密"
        case .libraryDelete: "删除"
        case .libraryDeleteConfirm: "确定要删除这段录音吗？此操作不可撤销。"
        case .libraryCancel: "取消"
        case .librarySavedEmpty: "还没有收藏任何声景。"
        case .libraryMyEmpty: "还没有录制任何声景。"
        case .libraryForYou: "为你"
        case .libraryClose: "关闭"
        case .libraryForYouEntrySubtitle: "用一段想法或声音塑造私人声景"
        case .libraryAccountMenu: "账号菜单"
        case .librarySignedOutTitle: "登录后查看你的声音库"
        case .librarySignedOutDetail: "使用 Panor 账号发布、设为私密或删除自己的录音。"
        case .librarySignInOrRegister: "登录或注册"
        case .libraryReadingRecordings: "正在读取你的录音"
        case .libraryNoRecordingsTitle: "还没有录音"
        case .libraryNoRecordingsDetail: "去创作页捕捉第一段真实环境声。"
        case .libraryPlayFeaturedRecording: "播放精选录音"
        case .libraryFilterRecordings: "录音"
        case .libraryFilterPublic: "公开"
        case .libraryFilterPrivate: "私密"
        case .libraryYourSoundArchive: "你的声音档案"
        case .settingsSectionAccount: "账户"
        case .settingsSectionPrivacy: "隐私"
        case .settingsSectionGeneral: "通用"
        case .settingsSectionForYou: "为你推荐"
        case .settingsTitle: "设置"
        case .settingsAccount: "账户与安全"
        case .settingsPrivacyPolicy: "隐私政策"
        case .settingsTermsOfService: "服务条款"
        case .settingsAppVersion: "应用版本"
        case .settingsLogout: "退出登录"
        case .settingsLogoutConfirm: "确定要退出登录吗？"
        case .settingsLanguage: "语言"
        case .settingsLanguageSystem: "跟随系统"
        case .settingsPrivacyBody: "Soundscape 重视你的隐私。\n\n你的录音默认仅自己可见，除非你选择公开发布。\n\n我们不会出售你的数据，也不会未经允许分享你的位置。\n\n所有音频上传和播放均通过加密连接传输。\n\n如需删除数据，请联系 support@panor.tech。"
        case .settingsTermsBody: "使用 Soundscape 即表示你同意：\n\n1. 不发布违规或侵权内容\n2. 尊重他人隐私和知识产权\n3. 遵守当地法律法规\n\n我们保留移除违规内容的权利。\n\n完整条款请访问 panor.tech/terms。"
        case .settingsResetRecommendations: "重置推荐"
        case .settingsResetRecommendationsConfirm: "清除设备上的短期和长期推荐画像？公开内容和账号不会被删除。"
        case .settingsResetRecommendationsDone: "推荐画像已重置"
        case .libraryPrivateUntilSignIn: "登录前为私密"
        case .librarySoundRecorder: "录音器"
        case .libraryMyRecordingsHeader: "我的录音"
        case .libraryPublicLabel: "公开"
        case .libraryPrivateLabel: "私密"
        case .errorCannotPlay: "播放器尚未载入音频。"
        case .errorNoAudio: "这段声景没有可播放的音频。"
        case .errorAudioDeviceDisconnected: "音频输出设备已断开，播放已暂停。"
        case .errorNetworkFailed: "请求失败，请稍后重试。"
        case .errorTryAgain: "请稍后再试。"
        case .errorInvalidImage: "无法识别所选封面图片。"
        case .errorCannotProcessImage: "无法处理所选封面图片。"
        case .errorInvalidURL: "无效的请求地址。"
        case .errorInvalidParams: "无效的请求参数。"
        case .errorServerFailed: "请求失败，请稍后重试。"
        case .errorSelectM4A: "请选择 M4A、AAC、MP3 或 WAV 音频。"
        case .errorCoverEmpty: "封面图片为空。"
        case .errorAudioEmpty: "音频文件为空。"
        case .errorAudioTooLarge: "音频不能超过 50 MB。"
        case .errorCoverTooLarge: "封面不能超过 12 MB。"
        case .errorTitleRequired: "请填写声景标题。"
        case .errorTitleTooLong: "标题不能超过 80 个字符。"
        case .errorDescriptionTooLong: "描述不能超过 500 个字符。"
        case .errorLocationNameTooLong: "地点名称不能超过 160 个字符。"
        case .errorLoginRequired: "请先登录后继续。"
        case .errorNetworkUnavailable: "网络连接失败，请稍后重试。"
        case .errorTitleGenerationFailed: "暂时无法生成标题和描述，请稍后重试或手动填写。"
        case .errorCoverGenerationFailed: "暂时无法生成封面，请稍后重试或上传自己的封面。"
        case .errorServerDataUnrecognized: "服务器返回了无法识别的数据。"
        case .errorKeychainFailed: "无法安全保存登录状态，请重新打开应用后重试。"
        case .errorAccountCreatedButCantSave: "账号已创建，但无法保存登录状态，请切换到登录后重试。"
        case .errorAudioPlaybackUnavailable: "当前无法启动音频播放，请稍后重试。"
        case .errorMicPermission: "未获得麦克风权限，请在系统设置中开启。"
        case .errorRecordingFailed: "当前无法开始录音。"
        case .errorLocationUnavailable: "暂时无法获取位置。"
        case .errorLocationUnavailableCanPublish: "你仍可不带位置发布。"
        case .errorNoPlayableReady: "暂时没有可播放的声景。"
        case .errorPersonalizationUnavailable: "暂时无法读取或保存个性化数据，请稍后重试。"
        case .errorUsernameRequired: "请输入用户名。"
        case .errorPasswordTooShort: "密码至少需要 6 个字符。"
        case .errorEmailRequired: "请输入邮箱。"
        case .errorGeneric: "错误"
        case .forYouEyebrow: "私人塑造"
        case .forYouTitle: "从任何想法开始。"
        case .forYouDetail: "写下此刻的想法、自由说话，或录下身边的世界。"
        case .forYouPrivateByDefault: "默认私密"
        case .forYouAnySound: "任何声音或想法"
        case .forYouCannotAutoPlay: "无法自动播放"
        case .forYouListeningShaping: "聆听 · 塑造中"
        case .forYouAnythingPlaceholder: "写下任何想法…"
        case .forYouPrivateInput: "私密输入"
        case .forYouMakeSoundscape: "生成我的声景"
        case .forYouGuideMe: "引导我"
        case .forYouGuidedQuestion: "现在听到什么会对你有帮助？"
        case .forYouGuidedPlaceholder: "用自己的话回答"
        case .forYouMakeNow: "立即生成我的声景"
        case .forYouMicrophoneTitle: "只有在你主动录音时，Soundscape 才会聆听。"
        case .forYouMicrophoneDetail: "录音默认为私密，分析后会被删除，除非你选择保留。"
        case .forYouRecord: "录音"
        case .forYouStop: "停止"
        case .generalOK: "好"
        case .generalCancel: "取消"
        case .generalRetry: "再试一次"
        case .generalLoading: "正在加载…"
        case .generalBack: "返回"
        case .generalContinue: "继续"
        case .generalNotNow: "暂不"
        case .generalDone: "完成"
        case .generalDismiss: "关闭"
        case .generalPrimaryNavigation: "主导航"
        case .appShellExplore: "探索"
        case .appShellMap: "地图"
        case .appShellContribute: "发布"
        case .appShellMe: "我的"
        case .coverLoadFailed: "封面加载失败"
        case .coverNoCover: "这段录音没有封面"
        case .coverAILabel: "AI 生成封面"
        case .coverAIBadge: "SOUNDSCAPE AI"
        case .coverLoading: "正在加载封面"
        case .unnamedSoundscape: "未命名声景"
        case .unknownLocation: "未知地点"
        case .soundscapeUnit: "声景"
        case .charactersUnit: "个字符"
        }
    }

    private var en: String {
        switch self {
        case .tabExplore: "Explore"
        case .tabMap: "Map"
        case .tabContribute: "Share"
        case .tabMe: "Me"
        case .tabExploreSubtitle: "Discover"
        case .tabRankingsSubtitle: "Rankings"
        case .exploreTitle: "Explore soundscapes"
        case .exploreEyebrow: "Discover recordings"
        case .exploreDetail: "Every recording comes from a real environment. Search by location or author, and filter by duration."
        case .exploreSearchPlaceholder: "Search soundscapes"
        case .exploreSearchAuthor: "Author"
        case .exploreSearchLocation: "Location"
        case .exploreSearchAll: "All"
        case .exploreDurationAny: "Any duration"
        case .exploreDurationUnder1min: "Under 1 min"
        case .exploreDuration1to5min: "1–5 min"
        case .exploreDurationOver5min: "Over 5 min"
        case .exploreLoading: "Loading soundscapes"
        case .exploreEmpty: "No public soundscapes yet. Publish the first one."
        case .exploreEmptyTitle: "It’s quiet here"
        case .exploreLoadingFailed: "Failed to load soundscapes"
        case .exploreBy: "Explore by"
        case .explorePopularSearches: "Popular searches"
        case .exploreRecentSearches: "Recent searches"
        case .exploreClear: "Clear"
        case .exploreClearSearch: "Clear search"
        case .exploreDeleteSearch: "Delete search"
        case .exploreLatestRecordings: "Latest recordings"
        case .exploreNoResultsTitle: "No matching recordings"
        case .exploreNoResultsDetail: "Try another location, author, category, or title."
        case .exploreTopResults: "Top results"
        case .exploreRecordings: "Recordings"
        case .explorePlayRecording: "Play"
        case .exploreFacetCategory: "Category"
        case .exploreFacetRecording: "Recording"
        case .exploreFacetDuration: "Duration"
        case .mapEyebrow: "Field atlas"
        case .mapTitle: "Sounds on the map"
        case .mapDetail: "Each dot is a real recording. Tap a location to see the author and start listening."
        case .mapLoading: "Loading recording coordinates"
        case .mapEmpty: "No map soundscapes yet. Recordings with locations will appear here."
        case .mapEmptyTitle: "No recordings on the map yet"
        case .mapShowAll: "Show all locations"
        case .mapSelectedRecording: "SELECTED RECORDING"
        case .mapPlayThis: "Play this recording"
        case .mapRecording: "Map recording"
        case .rankingsEyebrow: "Community picks"
        case .rankingsTitle: "Most played soundscapes"
        case .rankingsDetail: "Sounds the community loves."
        case .rankingsStillForming: "Rankings are still forming. Plays and saves will shape the order."
        case .rankingsPlayAndSaveHelp: "Plays and saves will shape the order."
        case .rankingsNatureParks: "Nature & Parks"
        case .rankingsUrbanAmbience: "Urban Ambience"
        case .rankingsMarketsCafes: "Markets & Cafés"
        case .rankingsLoading: "Loading rankings"
        case .rankingsFailed: "Failed to load rankings"
        case .rankingsLaneSuffix: " Rankings"
        case .playerSelectTrack: "Select a Track"
        case .playerDetails: "Details"
        case .playerRecordingDetails: "Recording Details"
        case .playerAuthor: "Author"
        case .playerLocation: "Location"
        case .playerDuration: "Duration"
        case .playerCategory: "Category"
        case .playerRecordedAt: "Recorded at"
        case .playerMadeForYou: "Made for you"
        case .playerFromExplore: "From Explore"
        case .playerFromMap: "From Map"
        case .playerFromRankings: "From Rankings"
        case .playerYourRecording: "Your recording"
        case .playerLoading: "Loading"
        case .playerNeedleParked: "Needle parked"
        case .playerNeedleOnRecord: "Needle on record"
        case .playerTurntable: "Turntable player"
        case .playerSave: "Save"
        case .playerUnsave: "Remove from saved"
        case .playerOpenDetailsHint: "Open recording details"
        case .playerSelectedTrack: "Selected"
        case .playerNeedle: "Tonearm"
        case .playerNeedlePaused: "Off the record, paused"
        case .playerNeedlePlaying: "On the record, playing"
        case .playerNeedleGestureHint: "Drag left or right to control playback; drag up or down to select a recording"
        case .playerPause: "Pause"
        case .playerPlay: "Play"
        case .playerOpenPlayer: "Open player"
        case .playerClosePlayer: "Close player"
        case .playerFeedbackTitle: "Does this sound fit?"
        case .playerFeedbackDetail: "Feedback adjusts this session first, then updates long-term taste more slowly."
        case .playerResonates: "Resonates"
        case .playerNotNow: "Not now"
        case .playerLessLikeThis: "Less like this"
        case .createEyebrow: "Public Contribution"
        case .createTitle: "Publish Soundscape"
        case .createDetail: "Record, import, enhance with AI, then publish. Your sound will appear in Explore and on the map."
        case .createRecordingDuration: "Recording duration"
        case .createImportAudio: "Import audio from file"
        case .createLocationSection: "Location"
        case .createTitleAndDescription: "Title & Description"
        case .createTitleField: "Title"
        case .createTitlePlaceholder: "Give this sound a name"
        case .createDescriptionField: "Description"
        case .createDescriptionPlaceholder: "One-line description"
        case .createThinkingGeneratingTitle: "Thinking, generating title and description"
        case .createCoverSection: "Cover"
        case .createAIGeneratingCover: "AI is generating cover"
        case .createAICoverHint: "AI cover is generated automatically; you can also upload your own to replace it."
        case .createChooseFromLibrary: "Choose from Library"
        case .createRegenerate: "Regenerate"
        case .createCategoryAndFeel: "Category & Feel"
        case .createCategoryLabel: "Category"
        case .createCategoryPlace: "Place"
        case .createCategoryNature: "Nature"
        case .createCategoryArchitecture: "Architecture"
        case .createPersonalToSocial: "Personal to Social"
        case .createPersonal: "Personal"
        case .createSocial: "Social"
        case .createMemoryToPresent: "Memory to Present"
        case .createMemory: "Memory"
        case .createPresent: "Present"
        case .createPublicToggle: "Publish to Explore & Map"
        case .createLoginToPublish: "Log in to publish"
        case .createPublishing: "Publishing"
        case .createPublishSoundscape: "Publish Soundscape"
        case .createPublished: "Published"
        case .createRecordAnother: "Record another"
        case .createLocating: "Getting current location..."
        case .createCurrentLocation: "Current location"
        case .createNoLocationPermission: "No location permission, will publish without location"
        case .createThinking: "Thinking"
        case .createRecordingState: "Recording, press again to stop"
        case .createRequestingPermission: "Requesting microphone permission"
        case .createReadyToRecord: "Press record to start capturing"
        case .createCannotReadCover: "Cannot read the selected cover."
        case .createSelectAudioFile: "Please select an audio file."
        case .createCannotReadAudio: "Cannot read the selected audio file."
        case .createDefaultPrompt: "Record a sound that makes you want to stop and listen"
        case .createListeningForMetadata: "AI is listening to the location and recording prompt…"
        case .identityLogin: "Log In"
        case .identityRegister: "Register"
        case .identityRegisterTitle: "Register"
        case .identityEmail: "Email"
        case .identityUsername: "Name (optional)"
        case .identityPassword: "Password"
        case .identityLoginButton: "Log In"
        case .identityRegisterButton: "Register"
        case .identitySwitchToRegister: "No account? Register"
        case .identitySwitchToLogin: "Have an account? Log in"
        case .identityLoggedInAs: "Logged in as"
        case .identityLogout: "Log Out"
        case .identityNeedLogin: "Login Required"
        case .identityLoginOrRegister: "Log in or Register"
        case .identityEyebrow: "Soundscape identity"
        case .identityTitle: "Save your sound archive"
        case .identityDetail: "Sign in to publish, save, and manage public or private recordings."
        case .identityOrContinueWith: "or"
        case .identityGoogleSignIn: "Sign in with Google"
        case .identityAppleSignIn: "Sign in with Apple"
        case .libraryEyebrow: "Your sound archive"
        case .libraryTitle: "Your Recordings & Saves"
        case .libraryDetail: "Manage the soundscapes you've created or saved."
        case .libraryLoading: "Loading your archive"
        case .libraryEmpty: "You have no recordings or saves yet."
        case .libraryMyRecordings: "My Recordings"
        case .librarySaved: "Saved"
        case .libraryMakePublic: "Make Public"
        case .libraryMakePrivate: "Make Private"
        case .libraryDelete: "Delete"
        case .libraryDeleteConfirm: "Are you sure you want to delete this recording? This cannot be undone."
        case .libraryCancel: "Cancel"
        case .librarySavedEmpty: "No saved soundscapes yet."
        case .libraryMyEmpty: "No recordings yet."
        case .libraryForYou: "For You"
        case .libraryClose: "Close"
        case .libraryForYouEntrySubtitle: "Shape a personal soundscape with a thought or sound"
        case .libraryAccountMenu: "Account Menu"
        case .librarySignedOutTitle: "Sign in to view your audio library"
        case .librarySignedOutDetail: "Use your Panor account to publish, make private, or delete your recordings."
        case .librarySignInOrRegister: "Sign In or Register"
        case .libraryReadingRecordings: "Reading your recordings"
        case .libraryNoRecordingsTitle: "No recordings yet"
        case .libraryNoRecordingsDetail: "Go capture your first real-world soundscape."
        case .libraryPlayFeaturedRecording: "Play featured recording"
        case .libraryFilterRecordings: "Recordings"
        case .libraryFilterPublic: "Public"
        case .libraryFilterPrivate: "Private"
        case .libraryYourSoundArchive: "Your sound archive"
        case .settingsSectionAccount: "Account"
        case .settingsSectionPrivacy: "Privacy"
        case .settingsSectionGeneral: "General"
        case .settingsSectionForYou: "For You"
        case .settingsTitle: "Settings"
        case .settingsAccount: "Account & Security"
        case .settingsPrivacyPolicy: "Privacy Policy"
        case .settingsTermsOfService: "Terms of Service"
        case .settingsAppVersion: "App Version"
        case .settingsLogout: "Log Out"
        case .settingsLogoutConfirm: "Are you sure you want to log out?"
        case .settingsLanguage: "Language"
        case .settingsLanguageSystem: "Follow System"
        case .settingsPrivacyBody: "Soundscape respects your privacy.\n\nYour recordings are private by default unless you choose to publish them.\n\nWe do not sell your data or share your location without permission.\n\nAll audio uploads and playback use encrypted connections.\n\nTo request data deletion, contact support@panor.tech."
        case .settingsTermsBody: "By using Soundscape, you agree to:\n\n1. Not publish unlawful or infringing content\n2. Respect other people’s privacy and intellectual property\n3. Follow applicable local laws\n\nWe may remove content that violates these terms.\n\nView the complete terms at panor.tech/terms."
        case .settingsResetRecommendations: "Reset recommendations"
        case .settingsResetRecommendationsConfirm: "Clear the short- and long-term recommendation profile stored on this device? Public content and your account stay unchanged."
        case .settingsResetRecommendationsDone: "Recommendation profile reset"
        case .libraryPrivateUntilSignIn: "Private until you sign in"
        case .librarySoundRecorder: "Sound recorder"
        case .libraryMyRecordingsHeader: "My Recordings"
        case .libraryPublicLabel: "Public"
        case .libraryPrivateLabel: "Private"
        case .errorCannotPlay: "Player has not loaded audio."
        case .errorNoAudio: "This soundscape has no playable audio."
        case .errorAudioDeviceDisconnected: "Audio output disconnected. Playback paused."
        case .errorNetworkFailed: "Request failed. Please try again later."
        case .errorTryAgain: "Please try again later."
        case .errorInvalidImage: "Cannot recognize the selected cover image."
        case .errorCannotProcessImage: "Cannot process the selected cover image."
        case .errorInvalidURL: "Invalid request URL."
        case .errorInvalidParams: "Invalid request parameters."
        case .errorServerFailed: "Request failed. Please try again later."
        case .errorSelectM4A: "Please select M4A, AAC, MP3, or WAV audio."
        case .errorCoverEmpty: "Cover image is empty."
        case .errorAudioEmpty: "Audio file is empty."
        case .errorAudioTooLarge: "Audio cannot exceed 50 MB."
        case .errorCoverTooLarge: "Cover cannot exceed 12 MB."
        case .errorTitleRequired: "Please enter a soundscape title."
        case .errorTitleTooLong: "Title cannot exceed 80 characters."
        case .errorDescriptionTooLong: "Description cannot exceed 500 characters."
        case .errorLocationNameTooLong: "Location name cannot exceed 160 characters."
        case .errorLoginRequired: "Please log in to continue."
        case .errorNetworkUnavailable: "Network unavailable. Please try again later."
        case .errorTitleGenerationFailed: "Unable to generate title and description. Please try again later or fill in manually."
        case .errorCoverGenerationFailed: "Unable to generate cover. Please try again later or upload your own."
        case .errorServerDataUnrecognized: "Server returned unrecognized data."
        case .errorKeychainFailed: "Unable to securely save login state. Please restart the app and try again."
        case .errorAccountCreatedButCantSave: "Account created but unable to save login state. Please switch to log in and try again."
        case .errorAudioPlaybackUnavailable: "Unable to start audio playback. Please try again later."
        case .errorMicPermission: "Microphone permission not granted. Please enable in System Settings."
        case .errorRecordingFailed: "Unable to start recording."
        case .errorLocationUnavailable: "Unable to get location."
        case .errorLocationUnavailableCanPublish: "You can still publish without location."
        case .errorNoPlayableReady: "No playable soundscape is ready yet."
        case .errorPersonalizationUnavailable: "Personalization data is unavailable right now. Please try again later."
        case .errorUsernameRequired: "Please enter a username."
        case .errorPasswordTooShort: "Password must be at least 6 characters."
        case .errorEmailRequired: "Please enter an email address."
        case .errorGeneric: "Error"
        case .forYouEyebrow: "Private shaping"
        case .forYouTitle: "Start with anything."
        case .forYouDetail: "Type what's on your mind, speak freely, or record the world around you."
        case .forYouPrivateByDefault: "Private by default"
        case .forYouAnySound: "Any sound or thought"
        case .forYouCannotAutoPlay: "Cannot auto-play"
        case .forYouListeningShaping: "Listening · Shaping"
        case .forYouAnythingPlaceholder: "Anything you want…"
        case .forYouPrivateInput: "Private input"
        case .forYouMakeSoundscape: "Make my soundscape"
        case .forYouGuideMe: "Guide me"
        case .forYouGuidedQuestion: "What would feel useful to hear right now?"
        case .forYouGuidedPlaceholder: "Answer in your own words"
        case .forYouMakeNow: "Make my soundscape now"
        case .forYouMicrophoneTitle: "Soundscape listens only when you record."
        case .forYouMicrophoneDetail: "Your recording is private and deleted after analysis unless you choose to keep it."
        case .forYouRecord: "Record"
        case .forYouStop: "Stop"
        case .generalOK: "OK"
        case .generalCancel: "Cancel"
        case .generalRetry: "Try Again"
        case .generalLoading: "Loading..."
        case .generalBack: "Back"
        case .generalContinue: "Continue"
        case .generalNotNow: "Not now"
        case .generalDone: "Done"
        case .generalDismiss: "Dismiss"
        case .generalPrimaryNavigation: "Primary navigation"
        case .appShellExplore: "Explore"
        case .appShellMap: "Map"
        case .appShellContribute: "Share"
        case .appShellMe: "Me"
        case .coverLoadFailed: "Cover load failed"
        case .coverNoCover: "No cover for this recording"
        case .coverAILabel: "AI generated cover"
        case .coverAIBadge: "SOUNDSCAPE AI"
        case .coverLoading: "Loading cover"
        case .unnamedSoundscape: "Untitled soundscape"
        case .unknownLocation: "Unknown location"
        case .soundscapeUnit: "soundscape"
        case .charactersUnit: "characters"
        }
    }

    private var zhHant: String {
        switch self {
        case .tabExplore: "探索"
        case .tabMap: "地圖"
        case .tabContribute: "發佈"
        case .tabMe: "我的"
        case .tabExploreSubtitle: "發現"
        case .tabRankingsSubtitle: "榜單"
        case .exploreTitle: "探索身邊的聲景"
        case .exploreEyebrow: "Explore"
        case .exploreDetail: "每段錄音都來自真實環境；搜尋地點或作者，也可以按時長篩選。"
        case .exploreSearchPlaceholder: "搜尋聲景"
        case .exploreSearchAuthor: "作者"
        case .exploreSearchLocation: "地點"
        case .exploreSearchAll: "全部"
        case .exploreDurationAny: "任意時長"
        case .exploreDurationUnder1min: "1 分鐘以內"
        case .exploreDuration1to5min: "1–5 分鐘"
        case .exploreDurationOver5min: "5 分鐘以上"
        case .exploreLoading: "正在讀取聲景列表"
        case .exploreEmpty: "還沒有公開聲景，發佈第一條吧。"
        case .exploreEmptyTitle: "這裡還很安靜"
        case .exploreLoadingFailed: "聲景列表載入失敗"
        case .exploreBy: "按條件探索"
        case .explorePopularSearches: "熱門搜尋"
        case .exploreRecentSearches: "最近搜尋"
        case .exploreClear: "清除"
        case .exploreClearSearch: "清除搜尋"
        case .exploreDeleteSearch: "刪除搜尋"
        case .exploreLatestRecordings: "最新錄音"
        case .exploreNoResultsTitle: "沒有符合的聲音"
        case .exploreNoResultsDetail: "換一個真實地點、作者、類別或標題試試。"
        case .exploreTopResults: "最相關結果"
        case .exploreRecordings: "錄音"
        case .explorePlayRecording: "播放"
        case .exploreFacetCategory: "類別"
        case .exploreFacetRecording: "聲音"
        case .exploreFacetDuration: "時長"
        case .mapEyebrow: "聲音地圖"
        case .mapTitle: "聲音落在地圖上"
        case .mapDetail: "每個黑點都是一段真實錄音；選擇地點即可檢視作者並開始播放。"
        case .mapLoading: "正在讀取錄音座標"
        case .mapEmpty: "還沒有地圖聲景，帶位置發佈的錄音會出現在這裡。"
        case .mapEmptyTitle: "地圖上還沒有錄音"
        case .mapShowAll: "顯示全部錄音地點"
        case .mapSelectedRecording: "已選錄音"
        case .mapPlayThis: "播放這段錄音"
        case .mapRecording: "地圖錄音"
        case .rankingsEyebrow: "社群精選"
        case .rankingsTitle: "最多播放的聲景"
        case .rankingsDetail: "大家都喜歡的聲音。"
        case .rankingsStillForming: "榜單還在形成，播放和收藏會讓真實聲景逐漸排出順序。"
        case .rankingsPlayAndSaveHelp: "播放和收藏會讓真實聲景逐漸排出順序。"
        case .rankingsNatureParks: "自然公園"
        case .rankingsUrbanAmbience: "城市氛圍"
        case .rankingsMarketsCafes: "市場與咖啡館"
        case .rankingsLoading: "正在載入排行"
        case .rankingsFailed: "排行載入失敗"
        case .rankingsLaneSuffix: "排行"
        case .playerSelectTrack: "選擇聲音"
        case .playerDetails: "詳情"
        case .playerRecordingDetails: "錄音詳情"
        case .playerAuthor: "作者"
        case .playerLocation: "地點"
        case .playerDuration: "時長"
        case .playerCategory: "分類"
        case .playerRecordedAt: "錄製時間"
        case .playerMadeForYou: "為你推薦"
        case .playerFromExplore: "來自探索"
        case .playerFromMap: "來自地圖"
        case .playerFromRankings: "來自榜單"
        case .playerYourRecording: "你的錄音"
        case .playerLoading: "正在載入"
        case .playerNeedleParked: "唱針已移出"
        case .playerNeedleOnRecord: "唱針位於唱片上"
        case .playerTurntable: "唱片機播放器"
        case .playerSave: "收藏"
        case .playerUnsave: "取消收藏"
        case .playerOpenDetailsHint: "開啟聲音詳情"
        case .playerSelectedTrack: "已選擇"
        case .playerNeedle: "唱針"
        case .playerNeedlePaused: "唱片外，已暫停"
        case .playerNeedlePlaying: "唱片上，播放中"
        case .playerNeedleGestureHint: "左右拖動控制播放；上下拖動選擇聲音"
        case .playerPause: "暫停"
        case .playerPlay: "播放"
        case .playerOpenPlayer: "開啟播放器"
        case .playerClosePlayer: "關閉播放器"
        case .playerFeedbackTitle: "這段聲音適合你嗎？"
        case .playerFeedbackDetail: "回饋會優先調整目前工作階段，再緩慢更新長期偏好。"
        case .playerResonates: "有共鳴"
        case .playerNotNow: "不是現在"
        case .playerLessLikeThis: "少推薦這類"
        case .createEyebrow: "公開發佈"
        case .createTitle: "發佈聲景"
        case .createDetail: "錄音、匯入、AI 增強之後公開發佈，讓你的聲音出現在探索頁面和地圖上。"
        case .createRecordingDuration: "錄音時長"
        case .createImportAudio: "從檔案匯入音訊"
        case .createLocationSection: "地點"
        case .createTitleAndDescription: "標題和描述"
        case .createTitleField: "標題"
        case .createTitlePlaceholder: "給這段聲音起個名字"
        case .createDescriptionField: "描述"
        case .createDescriptionPlaceholder: "一句話描述"
        case .createThinkingGeneratingTitle: "思考中，正在生成標題和描述"
        case .createCoverSection: "封面"
        case .createAIGeneratingCover: "AI 正在自動生成封面"
        case .createAICoverHint: "AI 封面會自動生成；也可以上傳自己的封面覆蓋它。"
        case .createChooseFromLibrary: "從相簿選擇"
        case .createRegenerate: "重新自動生成"
        case .createCategoryAndFeel: "分類和感受"
        case .createCategoryLabel: "分類"
        case .createCategoryPlace: "地方"
        case .createCategoryNature: "自然"
        case .createCategoryArchitecture: "建築"
        case .createPersonalToSocial: "個人到社群"
        case .createPersonal: "個人"
        case .createSocial: "社群"
        case .createMemoryToPresent: "記憶到當下"
        case .createMemory: "記憶"
        case .createPresent: "當下"
        case .createPublicToggle: "公開到探索與地圖"
        case .createLoginToPublish: "登入後發佈"
        case .createPublishing: "正在發佈"
        case .createPublishSoundscape: "發佈聲景"
        case .createPublished: "已發佈"
        case .createRecordAnother: "再錄一段"
        case .createLocating: "正在獲取當前位置…"
        case .createCurrentLocation: "當前位置"
        case .createNoLocationPermission: "未獲得位置權限，將不帶位置發佈"
        case .createThinking: "思考中"
        case .createRecordingState: "錄音中，再按一次結束"
        case .createRequestingPermission: "正在請求麥克風權限"
        case .createReadyToRecord: "按下錄音鍵開始捕捉"
        case .createCannotReadCover: "無法讀取所選封面。"
        case .createSelectAudioFile: "請選擇一個音訊檔案。"
        case .createCannotReadAudio: "無法讀取所選音訊檔案。"
        case .createDefaultPrompt: "錄下一段讓你想停下腳步的聲音"
        case .createListeningForMetadata: "AI 正在聆聽地點與錄音提示…"
        case .identityLogin: "登入"
        case .identityRegister: "註冊"
        case .identityRegisterTitle: "註冊"
        case .identityEmail: "電子郵件"
        case .identityUsername: "姓名（選填）"
        case .identityPassword: "密碼"
        case .identityLoginButton: "登入"
        case .identityRegisterButton: "註冊"
        case .identitySwitchToRegister: "沒有帳號？去註冊"
        case .identitySwitchToLogin: "已有帳號？去登入"
        case .identityLoggedInAs: "已登入"
        case .identityLogout: "登出"
        case .identityNeedLogin: "需要登入"
        case .identityLoginOrRegister: "登入或註冊"
        case .identityEyebrow: "Soundscape 帳號"
        case .identityTitle: "保存你的聲音檔案"
        case .identityDetail: "登錄後可以發佈、收藏，並管理公開或私密的錄音。"
        case .identityOrContinueWith: "或"
        case .identityGoogleSignIn: "使用 Google 登入"
        case .identityAppleSignIn: "使用 Apple 登入"
        case .libraryEyebrow: "你的聲音檔案"
        case .libraryTitle: "你的錄音與收藏"
        case .libraryDetail: "管理你建立或收藏的聲景。"
        case .libraryLoading: "正在載入你的檔案"
        case .libraryEmpty: "你還沒有錄音或收藏。"
        case .libraryMyRecordings: "我的錄音"
        case .librarySaved: "已收藏"
        case .libraryMakePublic: "設為公開"
        case .libraryMakePrivate: "設為私密"
        case .libraryDelete: "刪除"
        case .libraryDeleteConfirm: "確定要刪除這段錄音嗎？此操作不可撤銷。"
        case .libraryCancel: "取消"
        case .librarySavedEmpty: "還沒有收藏任何聲景。"
        case .libraryMyEmpty: "還沒有錄製任何聲景。"
        case .libraryForYou: "為你"
        case .libraryClose: "關閉"
        case .libraryForYouEntrySubtitle: "用一段想法或聲音塑造私人聲景"
        case .settingsSectionAccount: "帳戶"
        case .settingsSectionPrivacy: "隱私"
        case .settingsSectionGeneral: "一般"
        case .settingsSectionForYou: "為你推薦"
        case .settingsTitle: "設定"
        case .settingsAccount: "帳戶與安全"
        case .settingsPrivacyPolicy: "隱私政策"
        case .settingsTermsOfService: "服務條款"
        case .settingsAppVersion: "應用版本"
        case .settingsLogout: "登出"
        case .settingsLogoutConfirm: "確定要登出嗎？"
        case .settingsLanguage: "語言"
        case .settingsLanguageSystem: "跟隨系統"
        case .settingsPrivacyBody: "Soundscape 重視你的隱私。\n\n你的錄音預設僅自己可見，除非你選擇公開發佈。\n\n我們不會出售你的資料，也不會未經允許分享你的位置。\n\n所有音訊上傳和播放均透過加密連線傳輸。\n\n如需刪除資料，請聯絡 support@panor.tech。"
        case .settingsTermsBody: "使用 Soundscape 即表示你同意：\n\n1. 不發佈違規或侵權內容\n2. 尊重他人隱私和智慧財產權\n3. 遵守當地法律法規\n\n我們保留移除違規內容的權利。\n\n完整條款請造訪 panor.tech/terms。"
        case .settingsResetRecommendations: "重設推薦"
        case .settingsResetRecommendationsConfirm: "清除裝置上的短期和長期推薦輪廓？公開內容和帳號不會被刪除。"
        case .settingsResetRecommendationsDone: "推薦輪廓已重設"
        case .libraryAccountMenu: "帳號選單"
        case .librarySignedOutTitle: "登錄後查看你的聲音庫"
        case .librarySignedOutDetail: "使用 Panor 帳號發佈、設為私密或刪除自己的錄音。"
        case .librarySignInOrRegister: "登錄或註冊"
        case .libraryReadingRecordings: "正在讀取你的錄音"
        case .libraryNoRecordingsTitle: "還沒有錄音"
        case .libraryNoRecordingsDetail: "去創作頁捕捉第一段真實環境聲。"
        case .libraryPlayFeaturedRecording: "播放精選錄音"
        case .libraryFilterRecordings: "錄音"
        case .libraryFilterPublic: "公開"
        case .libraryFilterPrivate: "私密"
        case .libraryYourSoundArchive: "你的聲音檔案"
        case .libraryPrivateUntilSignIn: "登入前為私密"
        case .librarySoundRecorder: "錄音器"
        case .libraryMyRecordingsHeader: "我的錄音"
        case .libraryPublicLabel: "公開"
        case .libraryPrivateLabel: "私密"
        case .errorCannotPlay: "播放器尚未載入音訊。"
        case .errorNoAudio: "這段聲景沒有可播放的音訊。"
        case .errorAudioDeviceDisconnected: "音訊輸出裝置已中斷，播放已暫停。"
        case .errorNetworkFailed: "請求失敗，請稍後重試。"
        case .errorTryAgain: "請稍後再試。"
        case .errorInvalidImage: "無法識別所選封面圖片。"
        case .errorCannotProcessImage: "無法處理所選封面圖片。"
        case .errorInvalidURL: "無效的請求地址。"
        case .errorInvalidParams: "無效的請求參數。"
        case .errorServerFailed: "請求失敗，請稍後重試。"
        case .errorSelectM4A: "請選擇 M4A、AAC、MP3 或 WAV 音訊。"
        case .errorCoverEmpty: "封面圖片為空。"
        case .errorAudioEmpty: "音訊檔案為空。"
        case .errorAudioTooLarge: "音訊不能超過 50 MB。"
        case .errorCoverTooLarge: "封面不能超過 12 MB。"
        case .errorTitleRequired: "請填寫聲景標題。"
        case .errorTitleTooLong: "標題不能超過 80 個字元。"
        case .errorDescriptionTooLong: "描述不能超過 500 個字元。"
        case .errorLocationNameTooLong: "地點名稱不能超過 160 個字元。"
        case .errorLoginRequired: "請先登入後繼續。"
        case .errorNetworkUnavailable: "網路連線失敗，請稍後重試。"
        case .errorTitleGenerationFailed: "暫時無法生成標題和描述，請稍後重試或手動填寫。"
        case .errorCoverGenerationFailed: "暫時無法生成封面，請稍後重試或上傳自己的封面。"
        case .errorServerDataUnrecognized: "伺服器返回了無法識別的資料。"
        case .errorKeychainFailed: "無法安全儲存登入狀態，請重新開啟應用後重試。"
        case .errorAccountCreatedButCantSave: "帳號已建立，但無法儲存登入狀態，請切換到登入後重試。"
        case .errorAudioPlaybackUnavailable: "當前無法啟動音訊播放，請稍後重試。"
        case .errorMicPermission: "未獲得麥克風權限，請在系統設定中開啟。"
        case .errorRecordingFailed: "當前無法開始錄音。"
        case .errorLocationUnavailable: "暫時無法獲取位置。"
        case .errorLocationUnavailableCanPublish: "你仍可不帶位置發佈。"
        case .errorNoPlayableReady: "暫時沒有可播放的聲景。"
        case .errorPersonalizationUnavailable: "暫時無法讀取或儲存個人化資料，請稍後重試。"
        case .errorUsernameRequired: "請輸入使用者名稱。"
        case .errorPasswordTooShort: "密碼至少需要 6 個字元。"
        case .errorEmailRequired: "請輸入電子郵件。"
        case .errorGeneric: "錯誤"
        case .forYouEyebrow: "私人塑造"
        case .forYouTitle: "從任何想法開始。"
        case .forYouDetail: "寫下此刻的想法、自由說話，或錄下身邊的世界。"
        case .forYouPrivateByDefault: "預設私密"
        case .forYouAnySound: "任何聲音或想法"
        case .forYouCannotAutoPlay: "無法自動播放"
        case .forYouListeningShaping: "聆聽 · 塑造中"
        case .forYouAnythingPlaceholder: "寫下任何想法…"
        case .forYouPrivateInput: "私密輸入"
        case .forYouMakeSoundscape: "生成我的聲景"
        case .forYouGuideMe: "引導我"
        case .forYouGuidedQuestion: "現在聽到什麼會對你有幫助？"
        case .forYouGuidedPlaceholder: "用自己的話回答"
        case .forYouMakeNow: "立即生成我的聲景"
        case .forYouMicrophoneTitle: "只有在你主動錄音時，Soundscape 才會聆聽。"
        case .forYouMicrophoneDetail: "錄音預設為私密，分析後會被刪除，除非你選擇保留。"
        case .forYouRecord: "錄音"
        case .forYouStop: "停止"
        case .generalOK: "好"
        case .generalCancel: "取消"
        case .generalRetry: "再試一次"
        case .generalLoading: "正在載入…"
        case .generalBack: "返回"
        case .generalContinue: "繼續"
        case .generalNotNow: "暫不"
        case .generalDone: "完成"
        case .generalDismiss: "關閉"
        case .generalPrimaryNavigation: "主導覽"
        case .appShellExplore: "探索"
        case .appShellMap: "地圖"
        case .appShellContribute: "發佈"
        case .appShellMe: "我的"
        case .coverLoadFailed: "封面載入失敗"
        case .coverNoCover: "這段錄音沒有封面"
        case .coverAILabel: "AI 生成封面"
        case .coverAIBadge: "SOUNDSCAPE AI"
        case .coverLoading: "正在載入封面"
        case .unnamedSoundscape: "未命名聲景"
        case .unknownLocation: "未知地點"
        case .soundscapeUnit: "聲景"
        case .charactersUnit: "個字元"
        }
    }
}

extension String {
    static func loc(_ key: SoundscapeLocale) -> String {
        LocaleManager.localize(key)
    }
}

func loc(_ key: SoundscapeLocale) -> String {
    LocaleManager.localize(key)
}
