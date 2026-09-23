class User {
  final String id;
  final String name;
  final String email;
  final String username;
  final String passwordHash;
  final String age;
  final String gender;
  final String createdAt;
  final int? initialAssessmentScore;
  final String? initialAssessmentCategory;
  final String supportStyle;
  final String focusWindow;
  final String reminderPreference;
  final String averageSleepTime;
  final String sleepDuration;
  final String dietPattern;
  final String physicalActivity;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.passwordHash,
    this.age = '',
    this.gender = 'Prefer not to say',
    required this.createdAt,
    this.initialAssessmentScore,
    this.initialAssessmentCategory,
    this.supportStyle = 'Gentle and encouraging',
    this.focusWindow = 'Not sure yet',
    this.reminderPreference = 'A few gentle reminders',
    this.averageSleepTime = 'Not set',
    this.sleepDuration = 'Not set',
    this.dietPattern = 'Not set',
    this.physicalActivity = 'Not set',
  });

  User copyWith({
    String? name,
    String? email,
    String? age,
    String? gender,
    int? initialAssessmentScore,
    String? initialAssessmentCategory,
    String? supportStyle,
    String? focusWindow,
    String? reminderPreference,
    String? averageSleepTime,
    String? sleepDuration,
    String? dietPattern,
    String? physicalActivity,
  }) =>
      User(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        username: username,
        passwordHash: passwordHash,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        createdAt: createdAt,
        initialAssessmentScore:
            initialAssessmentScore ?? this.initialAssessmentScore,
        initialAssessmentCategory:
            initialAssessmentCategory ?? this.initialAssessmentCategory,
        supportStyle: supportStyle ?? this.supportStyle,
        focusWindow: focusWindow ?? this.focusWindow,
        reminderPreference: reminderPreference ?? this.reminderPreference,
        averageSleepTime: averageSleepTime ?? this.averageSleepTime,
        sleepDuration: sleepDuration ?? this.sleepDuration,
        dietPattern: dietPattern ?? this.dietPattern,
        physicalActivity: physicalActivity ?? this.physicalActivity,
      );

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        username: j['username'] as String,
        passwordHash: j['passwordHash'] as String,
        age: j['age'] as String? ?? '',
        gender: j['gender'] as String? ?? 'Prefer not to say',
        createdAt: j['createdAt'] as String,
        initialAssessmentScore: j['initialAssessmentScore'] as int?,
        initialAssessmentCategory: j['initialAssessmentCategory'] as String?,
        supportStyle: j['supportStyle'] as String? ?? 'Gentle and encouraging',
        focusWindow: j['focusWindow'] as String? ?? 'Not sure yet',
        reminderPreference:
            j['reminderPreference'] as String? ?? 'A few gentle reminders',
        averageSleepTime: j['averageSleepTime'] as String? ?? 'Not set',
        sleepDuration: j['sleepDuration'] as String? ?? 'Not set',
        dietPattern: j['dietPattern'] as String? ?? 'Not set',
        physicalActivity: j['physicalActivity'] as String? ?? 'Not set',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'username': username,
        'passwordHash': passwordHash,
        'age': age,
        'gender': gender,
        'createdAt': createdAt,
        'initialAssessmentScore': initialAssessmentScore,
        'initialAssessmentCategory': initialAssessmentCategory,
        'supportStyle': supportStyle,
        'focusWindow': focusWindow,
        'reminderPreference': reminderPreference,
        'averageSleepTime': averageSleepTime,
        'sleepDuration': sleepDuration,
        'dietPattern': dietPattern,
        'physicalActivity': physicalActivity,
      };
}
