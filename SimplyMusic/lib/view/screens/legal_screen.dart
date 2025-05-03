import 'package:flutter/material.dart';
import 'package:music_magic/model/object_models/legal_packages.dart';

class LegalScreen extends StatelessWidget {
  LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text("Legal",
            style: TextStyle(fontSize: 25, color: Colors.white)),
        backgroundColor: const Color(0xFF191818),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: <Widget>[
            const Text(
              "App Version: 1.0.2",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 20),
            const Text(
              "Legal Information:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 20),
            const Text(
              "Ownership:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              "This app is owned by Elanus Software LLC, Delaware, USA.\n"
              "Please note that Elanus Software, LLC in Delaware has no affiliation or relation to Elanus Software in Dubai.\n\n"
              "All data is stored locally.\n\n",
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Text(
              "Disclaimer & User Responsibility:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              "By using this application, you acknowledge and agree to the following:\n\n"
              "1) User Responsibility: This application enables you to download audio files in formats such as .m4a or .webm from YouTube URLs that you provide. It is your sole responsibility to ensure that any content you download complies with YouTube’s Terms of Service, copyright laws, and any other applicable laws and regulations. You agree that you are solely responsible for the content you download and for any consequences that may arise from such downloads.\n"
              "2) No Endorsement or Guarantee: The application, its developer, and its owner do not endorse, warrant, or guarantee the legality, accuracy, or appropriateness of any content downloaded using this application. The application is provided for personal use only, and any commercial or public use of downloaded content is strictly your responsibility.\n"
              "3) Limitation of Liability: Under no circumstances shall the developer or owner of this application be liable for any direct, indirect, incidental, consequential, or punitive damages arising out of your use of the application, including but not limited to any legal issues or claims that result from downloading content. By using this application, you agree to indemnify and hold harmless the developer and owner from any and all claims, liabilities, damages, and expenses (including legal fees) arising out of or related to your use of the application.\n"
              "4) Compliance with Laws: You agree to use this application only for lawful purposes and in a manner that does not infringe the rights of, restrict, or inhibit anyone else’s use and enjoyment of the application. Any unauthorized use of downloaded content is solely your responsibility.\n\n"
              "By continuing to use this application, you acknowledge that you have read, understood, and agreed to this disclaimer.\n",
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 10),
            const Text(
              "Packages used in the app:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: packages.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "${packages[index].name} (Version: ${packages[index].version})",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        packages[index].license,
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
