import 'package:flutter/material.dart';

Future<Map<String, String>?> showJoinClassDialog(BuildContext context) {
  final TextEditingController classNameController = TextEditingController();
  final TextEditingController creatorNameController = TextEditingController();

  return showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false, // Prevent closing by tapping outside
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 📝 Title
              Text(
                "Join Classroom",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),

              // 🏫 Classroom Name Input
              TextField(
                controller: classNameController,
                decoration: InputDecoration(
                  labelText: "Classroom id",
                  prefixIcon: Icon(Icons.class_),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 👤 Creator Name Input
              TextField(
                controller: creatorNameController,
                decoration: InputDecoration(
                  labelText: "Youe Name",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🧭 Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final classroomName = classNameController.text.trim();
                      final creatorName = creatorNameController.text.trim();

                      if (classroomName.isEmpty || creatorName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill in all fields"),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context, {
                        "classroomid": classroomName,
                        "userName": creatorName,
                      });
                    },
                    child: const Text(
                      "Create",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
