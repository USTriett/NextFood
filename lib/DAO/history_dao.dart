import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryDAO{
  String foodID;
  String foodImage;
  String foodName;
  String? restaurantAddress;
  String? restaurantID;
  String restaurantName;
  DateTime timeStamp;
  HistoryDAO(this.foodID,
      this.foodImage,
      this.foodName,
      this.restaurantAddress,
      this.restaurantID,
      this.restaurantName,
      this.timeStamp);

  factory HistoryDAO.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic>? data = doc.data();

    return HistoryDAO(
      data?['food_id'],
      data?['food_image'],
      data?['food_name'],
      data?['restaurant_address'],
      data?['restaurant_id'],
      data?['restaurant_name'],
      (data?['time'] as Timestamp).toDate(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'foodID': foodID,
      'foodImage': foodImage,
      'foodName': foodName,
      'restaurantAddress': restaurantAddress,
      'restaurantID': restaurantID,
      'restaurantName': restaurantName,
      'timeStamp': timeStamp.toIso8601String(),
    };
  }

  factory HistoryDAO.fromMap(Map<String, Object?> map) {

    return HistoryDAO(
      map['foodID'] as String,
      map['foodImage'] as String,
      map['foodName'] as String,
      map['restaurantAddress'] as String?,
      map['restaurantID'] as String?,
      map['restaurantName'] as String,
      DateTime.parse(map['timeStamp'] as String),
    );
  }
}