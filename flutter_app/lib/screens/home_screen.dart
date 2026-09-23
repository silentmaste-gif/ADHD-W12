import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/history_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

const _moods = [
  (MoodLabel.happy, 'assets/mood_face_1.png', Color(0xFFCEEACB)),
  (MoodLabel.okay, 'assets/mood_face_2.png', Color(0xFFFEF9C3)),
  (MoodLabel.sad, 'assets/mood_face_3.png', Color(0xFFFFDAD6)),
  (MoodLabel.stressed, 'assets/mood_face_4.png', Color(0xFFFFEDD5)),
  (MoodLabel.overwhelmed, 'assets/mood_face_5.png', Color(0xFFCBE9E0)),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final todayEntries = app.history.where((e) => e.isToday).take(2).toList();
    final hasTodayAssessment = app.history
        .any((entry) => entry.isToday && entry.type == EntryType.assessment);
    final reminder = app.companionNotification ??
        (!hasTodayAssessment
            ? 'A gentle reminder: your daily check-in is ready whenever you are.'
            : null);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (reminder != null)
              MaterialBanner(
                content: Text(reminder),
                leading: const Icon(Icons.notifications_active_outlined),
                actions: [
                  TextButton(
                    onPressed: app.clearCompanionNotification,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Row(children: [
                        ClipOval(
                          child: Image.asset('assets/brain_logo.png',
                              width: 64, height: 64, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('Welcome,',
                                  style: TextStyle(
                                      fontSize: 14, color: AppColors.textMid)),
                              Text('${app.currentUser?.name ?? "there"}!',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark)),
                            ])),
                        _HeaderIconBtn(
                          icon: Icons.settings_outlined,
                          onTap: () => app.navigate(AppScreen.settings),
                        ),
                      ]),
                    ),

                    // Mood check-in stays close to the welcome header.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _MoodPanel(app: app),
                    ),
                    const SizedBox(height: 16),

                    // Chat + daily assessment
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        _ActionCard(
                          icon: Icons.chat_bubble_outline,
                          title: 'Chat',
                          subtitle: 'Talk and get support',
                          onTap: () => app.navigate(AppScreen.chat),
                        ),
                        const SizedBox(width: 12),
                        _ActionCard(
                          icon: Icons.today_outlined,
                          title: 'Daily Assessment',
                          subtitle: 'Track today\'s patterns',
                          onTap: () => app.navigate(AppScreen.assessment),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () => app.navigate(AppScreen.today),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppColors.border.withValues(alpha: 0.35)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.checklist_outlined,
                                color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${app.openTasks.length} open things in Today',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark),
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textMid),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Initial check-in summary
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () => app.navigate(AppScreen.initialAssessment),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppColors.border.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.mint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.assignment_outlined,
                                    color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Initial Assessment',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      app.currentUser
                                              ?.initialAssessmentCategory ??
                                          'Not completed',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMid),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.textMid),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _InitialGuidanceCard(app: app),
                    ),
                    const SizedBox(height: 24),

                    // Today's history
                    if (todayEntries.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Today',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark)),
                              GestureDetector(
                                onTap: () => app.navigate(AppScreen.history),
                                child: const Text('See all',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary)),
                              ),
                            ]),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: todayEntries
                              .map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.border
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Row(children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: e.type == EntryType.mood
                                                ? const Color(0xFFCEEACB)
                                                : const Color(0xFFE8DCFF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: e.type == EntryType.mood &&
                                                    e.mood != null
                                                ? ClipOval(
                                                    child: Image.asset(
                                                      e.mood!.assetPath,
                                                      width: 40,
                                                      height: 40,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.assignment_outlined,
                                                    size: 19,
                                                    color: AppColors.primary,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              Text(e.label,
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          AppColors.textDark)),
                                              Text(e.timestamp,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppColors.textMid)),
                                            ])),
                                      ]),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            AidhdBottomNav(active: AppScreen.home, onTap: app.navigate),
          ],
        ),
      ),
    );
  }
}

class _MoodPanel extends StatelessWidget {
  final AppProvider app;

  const _MoodPanel({required this.app});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How are you feeling today?',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 4),
            const Text('Choose a starting point for your check-in.',
                style: TextStyle(fontSize: 12, color: AppColors.textMid)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _moods.map((moodData) {
                final (mood, assetPath, color) = moodData;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    app.setSelectedMood(mood);
                    app.navigate(AppScreen.moodCheckin);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(assetPath, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(mood.displayName,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMid)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            height: 158,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                            color: Color(0xFFF2F4F2), shape: BoxShape.circle),
                        child: Icon(icon, color: AppColors.primary, size: 22)),
                    const SizedBox(height: 12),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Expanded(
                        child: Text(subtitle,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMid,
                                height: 1.4))),
                  ]),
            ),
          ),
        ),
      );
}

class _InitialGuidanceCard extends StatelessWidget {
  final AppProvider app;

  const _InitialGuidanceCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final user = app.currentUser;
    final screening = user?.initialAssessmentCategory;
    final routine = user?.averageSleepTime;
    final message = screening == null || routine == null || routine == 'Not set'
        ? 'Complete both initial check-ins so your companion can offer more personal suggestions.'
        : 'Your companion can use these answers to suggest support that fits your routine. Start with one gentle step and adjust it together in chat.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.lightbulb_outline, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textDark, height: 1.45)),
        ),
      ]),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      );
}
