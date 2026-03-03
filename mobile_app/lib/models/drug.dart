// medicine/list

class Drug {
  final String drug_name;
  final int drug_id;
  final String warning;

  const Drug({
    required this.drug_name,
    required this.drug_id,
    required this.warning,
  });

  factory Drug.fromJson(Map<String, dynamic> json) {
    return Drug(
      drug_name: json['drug_name'] as String,
      drug_id: json['drug_id'] as int,
      warning: json['warning'] as String,
    );
  }
}