import SwiftUI

/// New flow: RootView shows this once (when profile.healthProfile == nil)
/// before handing off to MainTabView. Mirrors the RN app's multi-step body/
/// fitness questionnaire — not previously ported to this native app, so
/// UserProfileService.setHealthProfile(_:) has been sitting unused. The
/// RN screens use a custom ruler-drag control for weight input; this port
/// uses a plain SwiftUI Slider with the same live BMI/projection feedback
/// instead of redrawing that control from scratch.
struct OnboardingView: View {
    @EnvironmentObject private var profileService: UserProfileService
    @EnvironmentObject private var workoutPlanService: WorkoutPlanService
    let onFinished: () -> Void
    let onSkip: () -> Void

    private enum Step: Int, CaseIterable {
        case basics, weight, targetWeight, projection, workoutLevel, concerns, activityLevel, generating
    }

    @State private var step: Step = .basics

    // Draft answers
    @State private var age: Double = 28
    @State private var gender: String = "female"
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    @State private var targetWeightKg: Double = 70
    @State private var workoutLevel: String = "easy"
    @State private var concerns: Set<String> = ["none"]
    @State private var activityIndex: Double = 1
    @State private var generationProgress: [Bool] = [false, false, false]
    @State private var generationError: String?

    private var bmi: Double {
        let h = heightCm / 100
        guard h > 0 else { return 0 }
        return weightKg / (h * h)
    }

    private var bmiCategory: (label: String, message: String) {
        switch bmi {
        case ..<18.5: return (L("onboarding.bmiUnder"), L("onboarding.bmiUnderMsg"))
        case 18.5..<25: return (L("onboarding.bmiNormal"), L("onboarding.bmiNormalMsg"))
        case 25..<30: return (L("onboarding.bmiOver"), L("onboarding.bmiOverMsg"))
        default: return (L("onboarding.bmiObese"), L("onboarding.bmiObeseMsg"))
        }
    }

    private var goal: String {
        if targetWeightKg < weightKg - 1 { return "lose" }
        if targetWeightKg > weightKg + 1 { return "gain" }
        return "maintain"
    }

    private var projectionDate: Date {
        let deltaKg = abs(targetWeightKg - weightKg)
        let weeks = max(1, deltaKg / 0.5)
        return Calendar.current.date(byAdding: .day, value: Int(weeks * 7), to: Date()) ?? Date()
    }

    private static let activityDescriptions = [
        "onboarding.activitySedentaryDesc",
        "onboarding.activityLightDesc",
        "onboarding.activityModerateDesc",
        "onboarding.activityActiveDesc",
        "onboarding.activityVeryActiveDesc",
    ]
    private static let activityMultipliers = [1.2, 1.375, 1.55, 1.725, 1.9]
    private static let activityWeeklyWorkouts = [1, 3, 4, 5, 6]

    var body: some View {
        VStack(spacing: 0) {
            if step != .generating {
                header
            }

            Group {
                switch step {
                case .basics: basicsStep
                case .weight: weightStep
                case .targetWeight: targetWeightStep
                case .projection: projectionStep
                case .workoutLevel: workoutLevelStep
                case .concerns: concernsStep
                case .activityLevel: activityLevelStep
                case .generating: generatingStep
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.horizontal)
            .padding(.top, 24)

            if step != .generating {
                nextButton
                    .padding()
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    // MARK: - Chrome

    private func sectionInfo(for step: Step) -> (number: String, title: String, segment: Int, total: Int) {
        switch step {
        case .basics: return ("01", L("onboarding.sectionBasics"), 0, 1)
        case .weight: return ("02", L("onboarding.sectionBody"), 0, 3)
        case .targetWeight: return ("02", L("onboarding.sectionBody"), 1, 3)
        case .projection: return ("02", L("onboarding.sectionBody"), 2, 3)
        case .workoutLevel: return ("03", L("onboarding.sectionAssessment"), 0, 3)
        case .concerns: return ("03", L("onboarding.sectionAssessment"), 1, 3)
        case .activityLevel: return ("03", L("onboarding.sectionAssessment"), 2, 3)
        case .generating: return ("", "", 0, 1)
        }
    }

    private var header: some View {
        let info = sectionInfo(for: step)
        return VStack(spacing: 12) {
            HStack {
                Button {
                    goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(AppTheme.text)
                }
                .opacity(step == .basics ? 0 : 1)
                .disabled(step == .basics)

                Spacer()
                Text("\(info.number) \(info.title)".uppercased())
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(AppTheme.brandAccent)
                Spacer()
                Button(L("onboarding.skip")) { onSkip() }
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(AppTheme.subtext)
            }

            HStack(spacing: 6) {
                ForEach(0..<info.total, id: \.self) { index in
                    Capsule()
                        .fill(index <= info.segment ? AppTheme.brandAccent : AppTheme.border)
                        .frame(height: 4)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private var nextButton: some View {
        Button {
            goNext()
        } label: {
            Text(L("common.next"))
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.tabBarBackground)
                .cornerRadius(28)
        }
    }

    private func goBack() {
        guard let idx = Step.allCases.firstIndex(of: step), idx > 0 else { return }
        step = Step.allCases[idx - 1]
    }

    private func goNext() {
        guard let idx = Step.allCases.firstIndex(of: step), idx < Step.allCases.count - 1 else { return }
        step = Step.allCases[idx + 1]
        if step == .generating {
            Task { await runGeneration() }
        }
    }

    // MARK: - Steps

    private var basicsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(L("onboarding.basicsTitle"))
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(AppTheme.text)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L("onboarding.age")).font(.subheadline).foregroundColor(AppTheme.subtext)
                    HStack {
                        Slider(value: $age, in: 15...80, step: 1)
                        Text("\(Int(age))")
                            .font(.headline)
                            .frame(width: 40, alignment: .trailing)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L("onboarding.gender")).font(.subheadline).foregroundColor(AppTheme.subtext)
                    HStack(spacing: 12) {
                        genderButton(value: "female", label: L("onboarding.female"))
                        genderButton(value: "male", label: L("onboarding.male"))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L("onboarding.height")).font(.subheadline).foregroundColor(AppTheme.subtext)
                    HStack {
                        Slider(value: $heightCm, in: 140...210, step: 1)
                        Text("\(Int(heightCm)) cm")
                            .font(.headline)
                            .frame(width: 70, alignment: .trailing)
                    }
                }
            }
        }
    }

    private func genderButton(value: String, label: String) -> some View {
        let isSelected = gender == value
        return Button {
            gender = value
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? AppTheme.brandAccent : AppTheme.cardBackground)
                .foregroundColor(isSelected ? .white : AppTheme.text)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? Color.clear : AppTheme.border))
                .cornerRadius(14)
        }
    }

    private var weightStep: some View {
        measurementStep(
            title: L("onboarding.currentWeightTitle"),
            value: $weightKg,
            range: 30...200
        ) {
            VStack(spacing: 8) {
                HStack {
                    Text(L("onboarding.yourBmi"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.text)
                    Text("(\(bmiCategory.label))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.green)
                }
                HStack(alignment: .top, spacing: 12) {
                    Text(String(format: "%.1f", bmi))
                        .font(.title.bold())
                        .foregroundColor(.green)
                    Text(bmiCategory.message)
                        .font(.footnote)
                        .foregroundColor(AppTheme.subtext)
                }
            }
            .padding()
            .background(AppTheme.brandAccent.opacity(0.08))
            .cornerRadius(14)
        }
    }

    private var targetWeightStep: some View {
        measurementStep(
            title: L("onboarding.targetWeightTitle"),
            value: $targetWeightKg,
            range: 30...200
        ) {
            let deltaPercent = weightKg > 0 ? abs(targetWeightKg - weightKg) / weightKg * 100 : 0
            return VStack(alignment: .leading, spacing: 6) {
                Text(goal == "maintain" ? L("onboarding.goalMaintain") : (deltaPercent > 10 ? L("onboarding.goalChallenging") : L("onboarding.goalGreat")))
                    .font(.headline)
                    .foregroundColor(deltaPercent > 10 ? .red : AppTheme.text)
                if goal != "maintain" {
                    Text(String(format: L(goal == "gain" ? "onboarding.willGain" : "onboarding.willLose"), deltaPercent))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.text)
                }
            }
            .padding()
            .background(AppTheme.statBlue)
            .cornerRadius(14)
        }
    }

    private func measurementStep(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        @ViewBuilder feedback: () -> some View
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppTheme.text)

                VStack(spacing: 12) {
                    Text(String(format: "%.1f kg", value.wrappedValue))
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(AppTheme.text)
                    Slider(value: value, in: range, step: 0.5)
                }
                .frame(maxWidth: .infinity)

                feedback()
            }
        }
    }

    private var projectionStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(L("onboarding.projectionLead"))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.subtext)

                Text("\(String(format: "%.1f", targetWeightKg)) kg")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(AppTheme.text)
                + Text(" \(L("onboarding.on")) ")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.subtext)
                + Text(projectionDate.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.brandAccent)

                HStack {
                    VStack(alignment: .leading) {
                        Text(String(format: "%.1f kg", weightKg)).font(.headline).foregroundColor(AppTheme.text)
                        Text(L("common.today")).font(.caption).foregroundColor(AppTheme.subtext)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundColor(AppTheme.brandAccent)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(String(format: "%.1f kg", targetWeightKg)).font(.headline).foregroundColor(AppTheme.brandAccent)
                        Text(projectionDate.formatted(.dateTime.month(.abbreviated).day())).font(.caption).foregroundColor(AppTheme.subtext)
                    }
                }
                .padding()
                .background(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border))
                .cornerRadius(14)

                VStack(alignment: .leading, spacing: 6) {
                    Text(L("onboarding.greatStart")).font(.headline).foregroundColor(AppTheme.text)
                    Text(L("onboarding.greatStartMsg")).font(.subheadline).foregroundColor(AppTheme.subtext)
                }
            }
        }
    }

    private var workoutLevelStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L("onboarding.workoutLevelTitle"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppTheme.text)
                    .padding(.bottom, 8)

                levelOption(value: "easy", icon: "hand.raised.fill", label: L("onboarding.easyToStart"))
                if workoutLevel == "easy" {
                    HStack(alignment: .top, spacing: 10) {
                        Text("😊")
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("onboarding.dontWorry")).font(.subheadline.weight(.semibold))
                            Text(L("onboarding.dontWorryMsg")).font(.footnote).foregroundColor(AppTheme.subtext)
                        }
                    }
                    .padding()
                    .background(AppTheme.brandAccent.opacity(0.08))
                    .cornerRadius(14)
                }
                levelOption(value: "medium", icon: "drop.fill", label: L("onboarding.breakSweat"))
                levelOption(value: "hard", icon: "figure.strengthtraining.traditional", label: L("onboarding.bitChallenging"))
            }
        }
    }

    private func levelOption(value: String, icon: String, label: String) -> some View {
        let isSelected = workoutLevel == value
        return Button {
            workoutLevel = value
        } label: {
            HStack {
                Image(systemName: icon)
                Text(label).font(.headline)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .padding()
            .foregroundColor(isSelected ? .white : AppTheme.text)
            .background(isSelected ? AppTheme.brandAccent : AppTheme.cardBackground)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color.clear : AppTheme.border))
            .cornerRadius(16)
        }
    }

    private var concernsStep: some View {
        let options: [(String, String, String)] = [
            ("none", "circle.slash", L("onboarding.none")),
            ("knee", "figure.walk", L("onboarding.knee")),
            ("lowerBack", "figure.stand", L("onboarding.lowerBack")),
            ("shoulder", "figure.arms.open", L("onboarding.shoulder")),
        ]
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L("onboarding.concernsTitle"))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.text)

                HStack(alignment: .top, spacing: 10) {
                    Text("🩹")
                    Text(L("onboarding.concernsMsg"))
                        .font(.footnote)
                        .foregroundColor(AppTheme.subtext)
                }
                .padding()
                .background(AppTheme.brandAccent.opacity(0.08))
                .cornerRadius(14)

                ForEach(options, id: \.0) { option in
                    let isSelected = concerns.contains(option.0)
                    Button {
                        toggleConcern(option.0)
                    } label: {
                        HStack {
                            Image(systemName: option.1)
                            Text(option.2).font(.headline)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.brandAccent)
                            }
                        }
                        .padding()
                        .foregroundColor(AppTheme.text)
                        .background(AppTheme.cardBackground)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? AppTheme.brandAccent : AppTheme.border, lineWidth: isSelected ? 1.5 : 1))
                        .cornerRadius(14)
                    }
                }
            }
        }
    }

    private func toggleConcern(_ value: String) {
        if value == "none" {
            concerns = ["none"]
        } else {
            concerns.remove("none")
            if concerns.contains(value) {
                concerns.remove(value)
            } else {
                concerns.insert(value)
            }
            if concerns.isEmpty { concerns = ["none"] }
        }
    }

    private var activityLevelStep: some View {
        VStack(spacing: 28) {
            Text(L("onboarding.activityLevelTitle"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.text)
                .multilineTextAlignment(.center)

            Image(systemName: "figure.walk")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.brandAccent)

            Text(L(Self.activityDescriptions[Int(activityIndex)]))
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.text)
                .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                Slider(value: $activityIndex, in: 0...4, step: 1)
                HStack {
                    Text(L("onboarding.sedentary")).font(.caption).foregroundColor(AppTheme.subtext)
                    Spacer()
                    Text(L("onboarding.active")).font(.caption).foregroundColor(AppTheme.subtext)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var generatingStep: some View {
        VStack(alignment: .leading, spacing: 32) {
            Spacer()
            Text(L("onboarding.coachCreating"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.text)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .center)

            generationRow(
                done: generationProgress[0],
                label: L("onboarding.analyzingBody"),
                value: "\(Int(heightCm))cm, \(String(format: "%.1f", weightKg))kg"
            )
            generationRow(
                done: generationProgress[1],
                label: L("onboarding.calculatingMetabolism"),
                value: generationProgress[1] ? "\(Int(computedTDEE))kcal" : ""
            )
            generationRow(
                done: generationProgress[2],
                label: L("onboarding.pickingExercises"),
                value: generationProgress[2] ? L("onboarding.fullBody") : ""
            )

            if let generationError {
                VStack(spacing: 12) {
                    Text(generationError)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await runGeneration() }
                    } label: {
                        Text(L("common.next"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.tabBarBackground)
                            .cornerRadius(24)
                    }
                    Button(L("onboarding.skipForNow")) { onSkip() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.subtext)
                }
                .padding(.top, 8)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 60)
    }

    private func generationRow(done: Bool, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.subheadline).foregroundColor(AppTheme.subtext)
            HStack {
                Text(value).font(.title3.bold()).foregroundColor(AppTheme.text)
                Spacer()
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.brandAccent)
                }
            }
            Capsule()
                .fill(done ? AppTheme.brandAccent : AppTheme.border)
                .frame(height: 6)
        }
    }

    // MARK: - Computation

    private var computedBMR: Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * age
        return gender == "male" ? base + 5 : base - 161
    }

    private var computedTDEE: Double {
        computedBMR * Self.activityMultipliers[Int(activityIndex)]
    }

    private var computedDailyCalories: Double {
        switch goal {
        case "lose": return computedTDEE - 500
        case "gain": return computedTDEE + 300
        default: return computedTDEE
        }
    }

    private func runGeneration() async {
        generationProgress = [false, false, false]
        generationError = nil

        try? await Task.sleep(nanoseconds: 500_000_000)
        generationProgress[0] = true

        try? await Task.sleep(nanoseconds: 500_000_000)
        generationProgress[1] = true

        try? await Task.sleep(nanoseconds: 500_000_000)
        generationProgress[2] = true

        let health = HealthProfile(
            age: Int(age),
            gender: gender,
            heightCm: heightCm,
            weightKg: weightKg,
            startWeightKg: weightKg,
            targetWeightKg: targetWeightKg,
            activityLevel: ["sedentary", "light", "moderate", "active", "veryActive"][Int(activityIndex)],
            weeklyWorkouts: Self.activityWeeklyWorkouts[Int(activityIndex)],
            goal: goal,
            concerns: Array(concerns),
            workoutLevel: workoutLevel,
            dailyCalories: computedDailyCalories,
            bmr: computedBMR,
            tdee: computedTDEE
        )

        // Must succeed before we leave onboarding — otherwise the next
        // profile reload finds no healthProfile and RootView sends the user
        // straight back to step one. See fetchOrCreateRecord's doc comment.
        let saved = await profileService.setHealthProfile(health)
        guard saved else {
            generationError = profileService.errorMessage ?? L("common.error")
            return
        }

        // start() marks the service account-available (needed for save() to
        // actually persist) but kicks off its load as a detached Task, so
        // plans.isEmpty right after calling it can't be trusted yet —
        // explicitly await load() too before checking.
        workoutPlanService.start(isAccountAvailable: true)
        await workoutPlanService.load()
        if workoutPlanService.plans.isEmpty {
            let split = WorkoutTemplateGenerator.resolvedWeeklySplit()
            workoutPlanService.addPlan(name: L("onboarding.firstPlanName"), days: split)
        }

        let todayAbbrev = DateFormatter().shortWeekdaySymbol(for: Date())
        if let todayItems = WorkoutTemplateGenerator.resolvedWeeklySplit()[todayAbbrev], !todayItems.isEmpty {
            let daily = DailyPlanService(dateKey: DateKey.today)
            daily.start(isAccountAvailable: true)
            await daily.load()
            for item in todayItems {
                if let exercise = ExerciseDataStore.shared.exercise(id: item.id) {
                    daily.addExercise(exercise, sets: item.sets, reps: item.reps)
                }
            }
            await daily.save()
        }

        onFinished()
    }
}

private extension DateFormatter {
    func shortWeekdaySymbol(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
}
