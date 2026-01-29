import Foundation

struct MockDataProvider {
    static let homeDashboard = HomeDashboardMock(
        userName: "Alex",
        greeting: "Ready to move?",
        profileImageURL: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuBwkxcspKoO02_3xQYfIHn52ppgtisyAA18dHU6eZI7VWWubcU-KT3hL70TTr8_DNdZXcwt3GUyRvRRJvzJLDwKwFPXa46N52DUsZfW5VPC_0RBmbtNgTYrnpS0EmmNEIQrAxfykKLC0KcIRNO9wLN-Wbqzl5MPluInYd8wT5crxu2WwJaB5pabHFAeWTdgzJtAJ0vQXGHXN18NBdIBz3rXyxLcGEYCAKZWXlEtAXdau3fwAoxwB2aSFzDcO4__odHZflitEzhi3q8")!,
        weeklyGoals: [
            GoalMock(title: "Workouts", value: "3", valueSuffix: "/5", icon: "fitness_center", colorHex: "#FF8577", progress: 0.6),
            GoalMock(title: "Active", value: "120", valueSuffix: "m", icon: "timer", colorHex: "#60A5FA", progress: 0.8)
        ],
        achievements: [
            AchievementMock(title: "Points", value: "1,240", subtitle: "Top 10% this week!", icon: "stars", colorHex: "#34D399", backgroundHex: "#D1FAE5"),
            AchievementMock(title: "League", value: "Gold", subtitle: "", icon: "emoji_events", colorHex: "#F59E0B", backgroundHex: "#FEF3C7")
        ],
        recommended: RecommendedMock(
            badge: "Today's Pick",
            title: "Morning Yoga",
            subtitle: "Perfect for flexibility & calm.",
            cta: "Start Now"
        ),
        quickStats: []
    )

    static let presetCheck = PresetCheckMock(
        mascotURL: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuDbaK8U3MnCc2_N0tUIJjNu5IG7I1ROsvDS7HDe8t2zA3jHAF9ovcDNAYhsH3B4DvzVBE7tPZj0R1ni3b8XqGYCnvw8ccCuoyAmtX-W8fFV5cYgB5hkDqkFaLWwYn-r5jMTErNx5lfRDZs9vYgFMd3tXjmzo1W3aX9e5RqHSxDOQWdWkQUvOanE79DyPI7-p2DL39dxsJ70RVotdxwOgaYk0REASTY8xZWZ4tS7z-vFe2PGbeRynqydPmbtIv2-5TwBDErj0Ldsuo8")!,
        energySelection: 1,
        locationSelection: 1,
        targetMinutes: 45
    )

    static let workoutPreview = WorkoutPreviewMock(
        title: "Upper Body Fun!",
        duration: "45m",
        energy: "High Energy",
        calories: "320",
        coachNote: "Yay! Your upper body is fully recovered! We added a bit more weight to keep things exciting.",
        routine: [
            RoutineItemMock(index: 1, title: "Barbell Bench Press", subtitle: "Chest • Compound"),
            RoutineItemMock(index: 2, title: "Incline Dumbbell Press", subtitle: "Upper Chest • Isolation"),
            RoutineItemMock(index: 3, title: "Overhead Press", subtitle: "Shoulders • Stability"),
            RoutineItemMock(index: 4, title: "Cable Chest Fly", subtitle: "Chest • Hypertrophy"),
            RoutineItemMock(index: 5, title: "Tricep Pushdown", subtitle: "Triceps • Isolation"),
            RoutineItemMock(index: 6, title: "Lateral Raises", subtitle: "Shoulders • Isolation")
        ]
    )

    static let workoutSession = WorkoutSessionMock(
        exerciseName: "Barbell Bench Press",
        currentExerciseIndex: "1 / 6",
        elapsedTime: "00:00",
        videoURL: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuCsDtt72x80n8kuCmwsg23gc2PBAT3TnGim__uZVMn4Bti0a7lEEOwCFRRH7yiNQgoYBEl6gM9eUIaJMDy56PF4RSvZYd0oC4TR-ExeXEoIKNjZ9vYD9TES0AMw0M2_N-N5Nr1LNzk5o-IkXUy3pj0tX-Sz-msoEHYahAS-lK1_IqdU_JmdL7lDuBUzAG8V6itQZWa7wQzTeJwGbFnej6kMHpyspWkQ21Ioo6JEvcVs6XreG6gm7WkGnIN58Q6r96mQr6ORIV7Jjas")!,
        currentSet: "2 / 4",
        weight: "60",
        reps: "10",
        weightUnit: "lb",
        restSeconds: 60,
        previousSets: [
            WorkoutSetMock(setIndex: 1, weight: "60", reps: "12"),
            WorkoutSetMock(setIndex: 2, weight: "65", reps: "10")
        ]
    )

    static let rest = RestMock(
        exerciseName: "Barbell Bench Press",
        currentExerciseIndex: "1 / 6",
        videoURL: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuCsDtt72x80n8kuCmwsg23gc2PBAT3TnGim__uZVMn4Bti0a7lEEOwCFRRH7yiNQgoYBEl6gM9eUIaJMDy56PF4RSvZYd0oC4TR-ExeXEoIKNjZ9vYD9TES0AMw0M2_N-N5Nr1LNzk5o-IkXUy3pj0tX-Sz-msoEHYahAS-lK1_IqdU_JmdL7lDuBUzAG8V6itQZWa7wQzTeJwGbFnej6kMHpyspWkQ21Ioo6JEvcVs6XreG6gm7WkGnIN58Q6r96mQr6ORIV7Jjas")!,
        restSeconds: 60,
        weightUnit: "lb",
        previousSets: [
            RestSetMock(setIndex: 1, weight: "60", reps: "12"),
            RestSetMock(setIndex: 2, weight: "65", reps: "10")
        ]
    )

    static let report = ReportMock(
        monthTitle: "10월 리포트",
        weightValue: "72.5",
        weightDelta: "-1.2kg",
        totalWorkouts: "24",
        prCount: "5",
        volume: "12.4",
        totalTime: "18.5"
    )

    static let historyList = HistoryListMock(
        title: "운동 기록",
        subtitle: "Logbook",
        records: [
            HistoryListItemMock(dateMonth: "Oct", dateDay: "25", title: "가슴 & 삼두", meta: "55m ● 8,400kg ● 18 sets"),
            HistoryListItemMock(dateMonth: "Oct", dateDay: "24", title: "등 & 이두", meta: "60m ● 9,200kg ● 20 sets"),
            HistoryListItemMock(dateMonth: "Oct", dateDay: "22", title: "실외 달리기", meta: "35m ● 320kcal ● 4.5km"),
            HistoryListItemMock(dateMonth: "Oct", dateDay: "20", title: "하체 (Legs)", meta: "70m ● 12.5t ● 24 sets")
        ]
    )

    static let historyDetail = HistoryDetailMock(
        dateTitle: "Oct 24, 2023",
        time: "54",
        volume: "12.4",
        sets: "18",
        aiNote: "Great chest recovery! Your Bench Press went up by 5%. Solid gains! 🎉"
    )

    static let library = LibraryMock(
        title: "운동 라이브러리",
        searchPlaceholder: "어떤 운동을 찾으세요?",
        categoryChips: ["전체", "가슴", "등", "하체", "어깨", "팔", "코어"],
        countText: "724개의 운동",
        items: [
            LibraryItemMock(title: "벤치 프레스", subtitle: "가슴 (CHEST)", equipment: "Barbell", imageURL: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuCQttwyEWF6qXJa4GlsWMkmUdU50FAKOOvJsbb29QdPbTjuKa6JM9KUHC8VXJmH3Z-qYpUjy02hX1TNGkUvM_a-26iyv0gLVRBmpFfw1s76dlndFD7QkmJ84pezsisXP9fknFMNZ91Toj9hNKyqu0PjsvHBYT5ak3ZjtSBovtZqK56i9viOSEw6vAxQOGMHxbNG1_TPg5QOVlWAeHgJtqGhHGfqCMYXvIdTEESZdGMamX_0NotvWS4BAuYL0s10rUHmCGErVbnmGXE")!),
            LibraryItemMock(title: "데드리프트", subtitle: "등 (BACK)", equipment: "Compound", imageURL: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuD31Hj9MkRMg5lQK90LgpZ0qcUvwuVmY2kOFc3Iedtzi-oPWhGlDNUuMM_HJmMaLDyWp7A4KAs1Cdq7LaMpIo4VY5ubIgojMQCxfvdO48x-F0AjRZmEtgLByV7NEHPCV-rH75MxiAVr23z9dqs_6K-Q7T5Cf-rViJ3Kcmga-CQ81tHMpIEn5iliPn2vW0r7zi9Mr-G3igHVqjs4YawPSI2bOoi_v7hn2ZuVKHFbynw4BCsyHCeNHeWmHJ1SYXCnY8srwSptRFdsDKQ")!)
        ]
    )

    static let exerciseDetail = ExerciseDetailMock(
        title: "Barbell Bench Press",
        description: "Let's pump those pecs! A great move for a strong chest and arms. 💪",
        heroURL: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuCUyk_A0ZAvBPbzKmC9ddJh6KwAfF5fHPOsqWS_cA4AcKWybACPncj6MQUvSMjQA4pr25S3lu6hrnJkd8_821ir86JS3ej4BHqiyl9BW2vmcKA8Kr9g82zzH249sz6TkmVCHprArcj_IZnJGbRm_8pjlTDXCiXq59yUVJYeNQZA5syBhp1UxXS00G0xn_qEBz28RhyXuYp43EWvXgQPiYHNH0Z4dI-h3HkF8_YujVi1Zkd-9iS-WHgkw6GD7E2mzHxBrDAqDXBa5W0")!
    )
}

struct HomeDashboardMock {
    let userName: String
    let greeting: String
    let profileImageURL: URL
    let weeklyGoals: [GoalMock]
    let achievements: [AchievementMock]
    let recommended: RecommendedMock
    let quickStats: [QuickStatMock]
}

struct GoalMock {
    let title: String
    let value: String
    let valueSuffix: String
    let icon: String
    let colorHex: String
    let progress: Double
}

struct AchievementMock {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let colorHex: String
    let backgroundHex: String
}

struct RecommendedMock {
    let badge: String
    let title: String
    let subtitle: String
    let cta: String
}

struct QuickStatMock {
    let title: String
    let value: String
    let icon: String
    let colorHex: String
}

struct PresetCheckMock {
    let mascotURL: URL
    let energySelection: Int
    let locationSelection: Int
    let targetMinutes: Int
}

struct WorkoutPreviewMock {
    let title: String
    let duration: String
    let energy: String
    let calories: String
    let coachNote: String
    let routine: [RoutineItemMock]
}

struct RoutineItemMock {
    let index: Int
    let title: String
    let subtitle: String
}

struct WorkoutSessionMock {
    let exerciseName: String
    let currentExerciseIndex: String
    let elapsedTime: String
    let videoURL: URL
    let currentSet: String
    let weight: String
    let reps: String
    let weightUnit: String
    let restSeconds: Int
    let previousSets: [WorkoutSetMock]
}

struct WorkoutSetMock {
    let setIndex: Int
    let weight: String
    let reps: String
}

struct RestMock {
    let exerciseName: String
    let currentExerciseIndex: String
    let videoURL: URL
    let restSeconds: Int
    let weightUnit: String
    let previousSets: [RestSetMock]
}

struct RestSetMock {
    let setIndex: Int
    let weight: String
    let reps: String
}

struct ReportMock {
    let monthTitle: String
    let weightValue: String
    let weightDelta: String
    let totalWorkouts: String
    let prCount: String
    let volume: String
    let totalTime: String
}

struct HistoryListMock {
    let title: String
    let subtitle: String
    let records: [HistoryListItemMock]
}

struct HistoryListItemMock {
    let dateMonth: String
    let dateDay: String
    let title: String
    let meta: String
}

struct HistoryDetailMock {
    let dateTitle: String
    let time: String
    let volume: String
    let sets: String
    let aiNote: String
}

struct LibraryMock {
    let title: String
    let searchPlaceholder: String
    let categoryChips: [String]
    let countText: String
    let items: [LibraryItemMock]
}

struct LibraryItemMock {
    let title: String
    let subtitle: String
    let equipment: String
    let imageURL: URL
}

struct ExerciseDetailMock {
    let title: String
    let description: String
    let heroURL: URL
}
