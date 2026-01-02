import 'package:flutter/material.dart';

class AppsDrawers extends StatefulWidget {
  const AppsDrawers({super.key});

  @override
  State<AppsDrawers> createState() => _AppsDrawersState();
}

class _AppsDrawersState extends State<AppsDrawers> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue,
            Colors.purple,
            Colors.green
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,   
        child: ListView(
           
          children: [
            UserAccountsDrawerHeader( 
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.grey,
                //backgroundImage: AssetImage('assets/images/user_avatar.png'),
              ),
              accountName: Text("Student Name",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              accountEmail: Text("student@example.com"),
            ),
            MenuList(title: "Home", iconData: Icons.home),
            MenuList(title: "Profile", iconData: Icons.person),
            MenuList(title: "Settings", iconData: Icons.settings),
            MenuList(title: "Logout", iconData: Icons.logout),
          ],
        ),
      ),
    );
  }
  
}

class MenuList extends StatelessWidget {
  final String title;
  final IconData iconData;

  const MenuList({super.key, required this.title, required this.iconData});




  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {},
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white54,
          borderRadius: BorderRadius.circular(15)
        ),
        child: Icon(iconData, color: Colors.white,),
    
      ), 
      title: Text(title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 
