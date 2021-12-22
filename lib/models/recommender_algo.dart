import 'dart:math';

class RecommenderAlgo {
  static double cosineSimularity({List userArray, List restautantArray}) {
    double production = 0;
    double userPower = 0;
    double restaurantsPower = 0;
    for (var i = 0; i < userArray.length; i++) {
      production += userArray[i] * restautantArray[i];
      userPower += pow(userArray[i], 2);
      restaurantsPower += pow(restautantArray[i], 2);
    }
    return production / (userPower * restaurantsPower);
  }

  static List updateCuisine({List userArray, List restaurantsArray}) {
    List newArray = [];
    double total = 0;
    for (var i = 0; i < userArray.length; i++) {
      total += userArray[i] + restaurantsArray[i];
      newArray.add(userArray[i] + restaurantsArray[i]);
    }
    return newArray.map((e) => e / total).toList();
  }
}
