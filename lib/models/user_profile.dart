enum HealthCondition {
  normal('Normal'),
  asthma('Asthma'),
  copd('COPD'),
  bronchitis('Bronchitis'),
  allergicRhinitis('Allergic Rhinitis'),
  sinusitis('Sinusitis'),
  postCovid('Post-COVID');

  final String label;
  const HealthCondition(this.label);
}

class UserProfile {
  String name;
  int age;
  String location;
  HealthCondition condition;

  UserProfile({
    this.name = 'User',
    this.age = 30,
    this.location = 'Mumbai, India',
    this.condition = HealthCondition.normal,
  });
}
