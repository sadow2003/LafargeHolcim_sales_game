import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/main.dart';

// ── User Card ─────────────────────────────────────────────────────────────────
class UserCard extends StatelessWidget {
  final String               uid;
  final Map<String, dynamic> data;
  //save the action of the user
  final VoidCallback         onEdit;
  final VoidCallback         onDelete;

  const UserCard({
    super.key,
    required this.uid,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final firstName   = data['firstName']   ?? '';
    final lastName    = data['lastName']    ?? '';
    final email       = data['email']       ?? '';
    final role        = data['role']        ?? 'salesperson';
    final totalPoints = data['totalPoints'] ?? 0;
    final rank        = data['rank']        ?? 0;
    final isAdmin     = role == 'admin';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isAdmin
              ? kSecondaryColor.withValues(alpha: 0.15)
              : kPrimaryColor.withValues(alpha: 0.1),
          child: Text(
            firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAdmin ? kSecondaryColor : kPrimaryColor,
            ),
          ),
        ),



        title: Text(
          '$firstName $lastName'.trim(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),


        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            Text(email, style: const TextStyle(fontSize: 12)),


            const SizedBox(height: 4),


            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? kSecondaryColor.withValues(alpha: 0.15)
                        : kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isAdmin ? 'Admin' : 'Salesperson',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isAdmin ? kSecondaryColor : kPrimaryColor,
                    ),
                  ),
                ),

                if (!isAdmin) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 13, color: Colors.amber.shade600),
                      const SizedBox(width: 2),
                      Text('$totalPoints pts',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.military_tech,
                          size: 13, color: Colors.blueGrey.shade400),
                      const SizedBox(width: 2),
                      Text(rank == 0 ? '—' : '#$rank',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),


        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [


            IconButton(
              icon: const Icon(Icons.edit_outlined, color: kPrimaryColor),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),


            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
