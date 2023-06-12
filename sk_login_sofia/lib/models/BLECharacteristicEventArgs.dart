class BLECharacteristicEventArgs {
  String? serviceGuid;
  String? characteristicGuid;
  List<int>? value;

  BLECharacteristicEventArgs({this.serviceGuid, this.characteristicGuid, this.value});
}
