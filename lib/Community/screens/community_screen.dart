import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psy_fi/Community/screens/Postcard.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<Map<String, dynamic>> posts = [
    {
      "name": "Kalpana Chawla",
      "username": "@kalpana",
      "message":
          "The path from dreams to success does exist.\n\nMay you have the vision to find it, the courage to get on to it and the perseverance to follow it",
      "likes": 0,
      "comments": 0,
      "liked": false,
    },
    {
      "name": "Dr Mae Jemison",
      "username": "@Maejemi",
      "message":
          "Don’t let anyone rob you of your imagination, your creativity, or your curiosity.\n\nIt’s your place in the world; it’s your life.",
      "likes": 0,
      "comments": 0,
      "liked": true
    },
    {
      "name": "J.K Rowling",
      "username": "@jkrowling",
      "message":
          "Believe in yourself\n\nIt all starts with us. We can be the change, the leader and the changemaker too. It is essential to focus on our power to drive change. It takes only one person with desire and determination to drive change. We do not need magic to transform our world. We carry all the power we need inside ourselves already. We have the power to imagine better ",
      "likes": 0,
      "comments": 0,
      "liked": false
    },
    {
      "name": "Mary Kom, Olympic Bronze Medallist in Boxing",
      "username": "@marykom",
      "message":
          "If I, being a mother of two, can win a medal, so can you all.\n\nTake me as an example and don’t give up.",
      "likes": 0,
      "comments": 0,
      "liked": true
    },
    {
      "name": "Oprah Winfrey, talk show host",
      "username": "@oprah",
      "message":
          "Think like a queen.\n\nA queen is not afraid to fail. Failure is another stepping stone to greatness",
      "likes": 0,
      "comments": 0,
      "liked": false
    },
    {
      "name": "𝘋𝘳. 𝘈𝘗𝘑 𝘈𝘣𝘥𝘶𝘭 𝘒𝘢𝘭𝘢𝘮",
      "username": "@iamkalam",
      "message":
          "𝘋𝘳𝘦𝘢𝘮 𝘪𝘴 𝘯𝘰𝘵 𝘵𝘩𝘢𝘵 𝘸𝘩𝘪𝘤𝘩 𝘺𝘰𝘶 𝘴𝘦𝘦 𝘸𝘩𝘪𝘭𝘦 𝘴𝘭𝘦𝘦𝘱𝘪𝘯𝘨;\n\n𝘪𝘵 𝘪𝘴 𝘴𝘰𝘮𝘦𝘵𝘩𝘪𝘯𝘨 𝘵𝘩𝘢𝘵 𝘥𝘰𝘦𝘴 𝘯𝘰𝘵 𝘭𝘦𝘵 𝘺𝘰𝘶 𝘴𝘭𝘦𝘦𝘱.",
      "likes": 0,
      "comments": 0,
      "liked": false
    },
    {
      "name": "Anonymous",
      "username": "@anon",
      "message": """सोचना छोड़ दे अब तू, आँसू भी पोंछ डाल,
उठ और देख दुनिया, कर कुछ तो कमाल।

क्यों बैठी है गुमसुम, क्या खोया है बता?
हर मुश्किल का हल है, थोड़ा हिम्मत तो दिखा।

आँखों में नमी क्यों है, चेहरे पे उदासी?
ज़िंदगी हसीन है, भर इसमें खुशी जरा सी।

मत कर तू ज़्यादा सोच, जो होगा सो होगा,
तू कर्म पे ध्यान दे, हर पल तेरा नया होगा।

रोने से नहीं बदलेगा कुछ भी यहाँ,
हंसकर जी ले हर पल, यही है असली दास्ताँ।""",
      "likes": 0,
      "comments": 0,
      "liked": false
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Community",
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return PostCard(post: posts[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
