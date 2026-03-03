// medicine/detail

class DrugDetailed {
  final int drug_id;
  final String drug_name;
  final int total_drugs;
  final int each_taken;
  final String timing;
  final String frequency;
  final String warning;
  final String description;
  final String image_url;
  final String user_id;
  final bool take_morning;
  final bool take_noon;
  final bool take_evening;
  final bool take_bedtime;
  final String start_date;
  final String? start_time;

  const DrugDetailed({
    required this.drug_id,
    required this.drug_name,
    required this.total_drugs,
    required this.each_taken,
    required this.timing,
    required this.frequency,
    required this.warning,
    required this.description,
    required this.image_url,
    required this.user_id,
    required this.take_morning,
    required this.take_noon,
    required this.take_evening,
    required this.take_bedtime,
    required this.start_date,
    required this.start_time,
});

  factory DrugDetailed.fromJson(Map<String, dynamic> json) {
    return DrugDetailed(
      drug_id: json['drug_id'] as int,
      drug_name: json['drug_name'] as String,
      total_drugs: json['total_drugs'] as int,
      each_taken: json['each_taken'] as int,
      timing: json['timing'] as String,
      frequency: json['frequency'] as String,
      warning: json['warning'] as String,
      description: json['description'] as String,
      image_url: json['image_url'] as String,
      user_id: json['user_id'] as String,
      take_morning: json['take_morning'] as bool,
      take_noon: json['take_noon'] as bool,
      take_evening: json['take_evening'] as bool,
      take_bedtime: json['take_bedtime'] as bool,
      start_date: json['start_date'] as String,
      start_time: json['start_time'] as String,
    );
  }
}