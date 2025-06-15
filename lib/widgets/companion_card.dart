import 'package:flutter/material.dart';
import '../model/companion_model.dart';
import '../data/companion_data.dart';

class CompanionCard extends StatelessWidget {
  final CompanionModel data;
  final String currentUser;

  const CompanionCard({
    Key? key,
    required this.data,
    required this.currentUser,
  }) : super(key: key);

  void _requestToJoin(BuildContext context) {
    print("RequestToJoin: currentUser=$currentUser, organiserName=${data.organiserName}");
    GroupModel? group;
    for (var g in groupData) {
      if (g.eventId == data.id) {
        group = g;
        break;
      }
    }
    if (group == null) {
      group = GroupModel(
        groupId: "group${groupData.length + 1}",
        eventId: data.id,
        groupName: "${data.sportName} Group by ${data.organiserName}",
        organiserName: data.organiserName,
        members: [data.organiserName],
      );
      groupData.add(group);
      print("Created new group: ${group.groupId} for event: ${group.eventId}");
      logGroupData("After group creation in request");
    }
    if (currentUser.toLowerCase() == data.organiserName.toLowerCase()) {
      if (!group.members.contains(currentUser)) {
        group.members.add(currentUser);
        print("Auto-added organiser $currentUser to group: ${group.groupId}");
        logGroupData("After auto-adding organiser");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You are the organiser of this group!")),
      );
      return;
    }
    pendingRequests.add(PendingRequest(
      userName: currentUser,
      groupId: group.groupId,
    ));
    print("Added request for user: $currentUser to group: ${group.groupId}");
    logGroupData("After adding request");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request sent to organiser!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    data.logoPath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          data.sportName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        Text(
                          "by ${data.organiserName}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF546E7A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${data.venue}, ${data.city}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF455A64),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${data.date} at ${data.time}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF78909C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.description,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF212121),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoTag("Gender: ${data.gender}"),
                        _buildInfoTag("Type: ${data.paidStatus}"),
                        _buildInfoTag("Age Limit: ${data.ageLimit}"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => _requestToJoin(context),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5E35B1),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              "Request",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF5E35B1),
        ),
      ),
    );
  }
}
