import '../model/companion_model.dart';

final List<CompanionModel> companionData = [
  CompanionModel(
    id: "event1",
    sportName: "Football",
    logoPath: "assets/images/football.jpg",
    organiserName: "Demo User",
    venue: "Nehru Stadium",
    city: "Delhi",
    description: "Looking for passionate football players for a weekend match.",
    date: "2025-05-18",
    time: "5:00 PM",
    gender: "All",
    ageLimit: "18-25",
    paidStatus: "Unpaid",
    food: "Not Included",
    travel: "Own Vehicle",
  ),
  CompanionModel(
    id: "event2",
    sportName: "Cricket",
    logoPath: "assets/images/cricket.jpg",
    organiserName: "Rahul Verma",
    venue: "Maidan Ground",
    city: "Mumbai",
    description: "Join our Sunday cricket league, open for all.",
    date: "2025-05-20",
    time: "10:00 AM",
    gender: "Male",
    ageLimit: "18-25",
    paidStatus: "Paid",
    food: "Included",
    travel: "Transport",
  ),
  CompanionModel(
    id: "event3",
    sportName: "Badminton",
    logoPath: "assets/images/badminton.jpg",
    organiserName: "Sneha Roy",
    venue: "Sports Complex",
    city: "Bangalore",
    description: "Join our badminton doubles match!",
    date: "2025-05-22",
    time: "6:00 PM",
    gender: "Female",
    ageLimit: "18-25",
    paidStatus: "Unpaid",
    food: "Included",
    travel: "Shared Cab",
  ),
];

final List<GroupModel> groupData = [
  GroupModel(
    groupId: "group1",
    eventId: "event1",
    groupName: "Delhi Football Crew",
    organiserName: "Demo User",
    members: ["Demo User"],
  ),
  GroupModel(
    groupId: "group2",
    eventId: "event3",
    groupName: "Bangalore Badminton Club",
    organiserName: "Sneha Roy",
    members: ["Sneha Roy"],
  ),
];

final List<PendingRequest> pendingRequests = [
  PendingRequest(
    userName: "Rahul Verma",
    groupId: "group1",
  ),
];

final Map<String, List<MessageModel>> groupMessages = {
  "group1": [
    MessageModel(
      sender: "Demo User",
      text: "Hey, ready for the match?",
      timestamp: "2025-05-16 14:00",
    ),
  ],
};

final List<String> availableUsers = [
  "Demo User",
  "Sneha Roy",
  "Rahul Verma",
];

void logGroupData(String context) {
  print("$context: groupData = ${groupData.map((g) => '${g.groupId}: ${g.groupName}, Organiser: ${g.organiserName}, Members: ${g.members}').toList()}");
}