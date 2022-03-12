import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../helps/containts.dart';

class TokenController extends GetxController{
  Future<String>getTokenByUserName(String userName)async{
    String token="";
    await FirebaseFirestore.instance.collection(Containts.USER_TOKEN).doc(userName).get().then((value){
      Map<String,dynamic>mapinfo=value.data() as Map<String,dynamic>;
      token=mapinfo["token"];
    });
    return token;
  }
}
