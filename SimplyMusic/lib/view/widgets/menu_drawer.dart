// ignore_for_file: camel_case_types, library_private_types_in_public_api, prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:music_magic/view/screens/legal_screen.dart';

class kDrawer_Menu extends StatefulWidget {
  const kDrawer_Menu({super.key});

  @override
  _kDrawer_MenuState createState() => _kDrawer_MenuState();
}

class _kDrawer_MenuState extends State<kDrawer_Menu> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Container(
        color: const Color(0xFF191818),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF191818),
              ),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
// ************************** DELETE/EDIT HELP **************************
            ExpansionTile(
              leading: const Icon(Icons.question_mark, color: Colors.white),
              title: const Text('Delete/Edit Help',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              children: [
                const Text('To delete, slide the item to the right:',
                    style: TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 10.0),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/delete_ex.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                const SizedBox(height: 25),
                const Text('To edit, slide the item to the left:',
                    style: TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 10.0),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/edit_ex.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
// ************************** ABOUT **************************
            ExpansionTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text('About',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              children: [
                ListTile(
                  leading: const Icon(Icons.balance, color: Colors.white),
                  title: const Text('Legal',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LegalScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
