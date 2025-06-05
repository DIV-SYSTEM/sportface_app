class CompanionModel {
  final String id;
  final String sportName;
  final String logoPath;
  final String organiserName;
  final String venue;
  final String city;
  final String description;
  final String date;
  final String time;

  // Existing fields
  final String gender;      // "All", "Male", "Female"
  final String ageLimit;    // "18-25", "26-33", ...
  final String paidStatus;  // "Paid" or "Unpaid"

  // New fields for filtering
  final String food;        // "Included", "Not Included"
  final String travel;      // "Own Vehicle", "Public Transport", "Shared Cab"

  CompanionModel({
    required this.id,
    required this.sportName,
    required this.logoPath,
    required this.organiserName,
    required this.venue,
    required this.city,
    required this.description,
    required this.date,
    required this.time,
    required this.gender,
    required this.ageLimit,
    required this.paidStatus,
    required this.food,
    required this.travel,
  });
}

class GroupModel {
  final String groupId;
  final String eventId;
  final String groupName;
  final String organiserName;
  final List<String> members;

  GroupModel({
    required this.groupId,
    required this.eventId,
    required this.groupName,
    required this.organiserName,
    required this.members,
  });
}

class MessageModel {
  final String sender;
  final String text;
  final String timestamp;

  MessageModel({
    required this.sender,
    required this.text,
    required this.timestamp,
  });
}

class PendingRequest {
  final String userName;
  final String groupId;

  PendingRequest({
    required this.userName,
    required this.groupId,
  });
}