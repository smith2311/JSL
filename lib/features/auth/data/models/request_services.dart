class RequestServiceFormData {
  final String? dateOfCollect;
  final String? timeSlot;
  final String? note;
  final String? mobileNo;
  final String? subject;
  final String? description;

  RequestServiceFormData({
    this.dateOfCollect,
    this.timeSlot,
    this.note,
    this.mobileNo,
    this.subject,
    this.description,
  });

  RequestServiceFormData copyWith({
    String? dateOfCollect,
    String? timeSlot,
    String? note,
    String? mobileNo,
    String? subject,
    String? description,
  }) {
    return RequestServiceFormData(
      dateOfCollect: dateOfCollect ?? this.dateOfCollect,
      timeSlot: timeSlot ?? this.timeSlot,
      note: note ?? this.note,
      mobileNo: mobileNo ?? this.mobileNo,
      subject: subject ?? this.subject,
      description: description ?? this.description,
    );
  }
}