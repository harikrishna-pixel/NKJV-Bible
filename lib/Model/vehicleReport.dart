/// deviceId : 811
/// deviceName : "UP61AV3008"
/// distance : 2344.3899999987334
/// averageSpeed : 2.900775975555403
/// maxSpeed : 12.419
/// spentFuel : 0.0
/// startOdometer : 1.033639297E7
/// endOdometer : 1.033873736E7
/// startTime : "2023-05-17T03:32:02.000+00:00"
/// endTime : "2023-05-17T03:58:13.000+00:00"
/// startPositionId : 198173192
/// endPositionId : 198221641
/// startLat : 25.626493333333336
/// startLon : 83.80274333333332
/// endLat : 25.62763
/// endLon : 83.82206
/// startAddress : null
/// endAddress : null
/// duration : 1571000
/// driverUniqueId : null
/// driverName : null
library;

class VehicleReport {
  VehicleReport({
    num? deviceId,
    String? deviceName,
    num? distance,
    num? averageSpeed,
    num? maxSpeed,
    num? spentFuel,
    num? startOdometer,
    num? endOdometer,
    String? startTime,
    String? endTime,
    num? startPositionId,
    num? endPositionId,
    num? startLat,
    num? startLon,
    num? endLat,
    num? endLon,
    dynamic startAddress,
    dynamic endAddress,
    num? duration,
    dynamic driverUniqueId,
    dynamic driverName,
  }) {
    _deviceId = deviceId;
    _deviceName = deviceName;
    _distance = distance;
    _averageSpeed = averageSpeed;
    _maxSpeed = maxSpeed;
    _spentFuel = spentFuel;
    _startOdometer = startOdometer;
    _endOdometer = endOdometer;
    _startTime = startTime;
    _endTime = endTime;
    _startPositionId = startPositionId;
    _endPositionId = endPositionId;
    _startLat = startLat;
    _startLon = startLon;
    _endLat = endLat;
    _endLon = endLon;
    _startAddress = startAddress;
    _endAddress = endAddress;
    _duration = duration;
    _driverUniqueId = driverUniqueId;
    _driverName = driverName;
  }

  VehicleReport.fromJson(dynamic json) {
    _deviceId = json['deviceId'];
    _deviceName = json['deviceName'];
    _distance = json['distance'];
    _averageSpeed = json['averageSpeed'];
    _maxSpeed = json['maxSpeed'];
    _spentFuel = json['spentFuel'];
    _startOdometer = json['startOdometer'];
    _endOdometer = json['endOdometer'];
    _startTime = json['startTime'];
    _endTime = json['endTime'];
    _startPositionId = json['startPositionId'];
    _endPositionId = json['endPositionId'];
    _startLat = json['startLat'];
    _startLon = json['startLon'];
    _endLat = json['endLat'];
    _endLon = json['endLon'];
    _startAddress = json['startAddress'];
    _endAddress = json['endAddress'];
    _duration = json['duration'];
    _driverUniqueId = json['driverUniqueId'];
    _driverName = json['driverName'];
  }
  num? _deviceId;
  String? _deviceName;
  num? _distance;
  num? _averageSpeed;
  num? _maxSpeed;
  num? _spentFuel;
  num? _startOdometer;
  num? _endOdometer;
  String? _startTime;
  String? _endTime;
  num? _startPositionId;
  num? _endPositionId;
  num? _startLat;
  num? _startLon;
  num? _endLat;
  num? _endLon;
  dynamic _startAddress;
  dynamic _endAddress;
  num? _duration;
  dynamic _driverUniqueId;
  dynamic _driverName;
  VehicleReport copyWith({
    num? deviceId,
    String? deviceName,
    num? distance,
    num? averageSpeed,
    num? maxSpeed,
    num? spentFuel,
    num? startOdometer,
    num? endOdometer,
    String? startTime,
    String? endTime,
    num? startPositionId,
    num? endPositionId,
    num? startLat,
    num? startLon,
    num? endLat,
    num? endLon,
    dynamic startAddress,
    dynamic endAddress,
    num? duration,
    dynamic driverUniqueId,
    dynamic driverName,
  }) =>
      VehicleReport(
        deviceId: deviceId ?? _deviceId,
        deviceName: deviceName ?? _deviceName,
        distance: distance ?? _distance,
        averageSpeed: averageSpeed ?? _averageSpeed,
        maxSpeed: maxSpeed ?? _maxSpeed,
        spentFuel: spentFuel ?? _spentFuel,
        startOdometer: startOdometer ?? _startOdometer,
        endOdometer: endOdometer ?? _endOdometer,
        startTime: startTime ?? _startTime,
        endTime: endTime ?? _endTime,
        startPositionId: startPositionId ?? _startPositionId,
        endPositionId: endPositionId ?? _endPositionId,
        startLat: startLat ?? _startLat,
        startLon: startLon ?? _startLon,
        endLat: endLat ?? _endLat,
        endLon: endLon ?? _endLon,
        startAddress: startAddress ?? _startAddress,
        endAddress: endAddress ?? _endAddress,
        duration: duration ?? _duration,
        driverUniqueId: driverUniqueId ?? _driverUniqueId,
        driverName: driverName ?? _driverName,
      );
  num? get deviceId => _deviceId;
  String? get deviceName => _deviceName;
  num? get distance => _distance;
  num? get averageSpeed => _averageSpeed;
  num? get maxSpeed => _maxSpeed;
  num? get spentFuel => _spentFuel;
  num? get startOdometer => _startOdometer;
  num? get endOdometer => _endOdometer;
  String? get startTime => _startTime;
  String? get endTime => _endTime;
  num? get startPositionId => _startPositionId;
  num? get endPositionId => _endPositionId;
  num? get startLat => _startLat;
  num? get startLon => _startLon;
  num? get endLat => _endLat;
  num? get endLon => _endLon;
  dynamic get startAddress => _startAddress;
  dynamic get endAddress => _endAddress;
  num? get duration => _duration;
  dynamic get driverUniqueId => _driverUniqueId;
  dynamic get driverName => _driverName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['deviceId'] = _deviceId;
    map['deviceName'] = _deviceName;
    map['distance'] = _distance;
    map['averageSpeed'] = _averageSpeed;
    map['maxSpeed'] = _maxSpeed;
    map['spentFuel'] = _spentFuel;
    map['startOdometer'] = _startOdometer;
    map['endOdometer'] = _endOdometer;
    map['startTime'] = _startTime;
    map['endTime'] = _endTime;
    map['startPositionId'] = _startPositionId;
    map['endPositionId'] = _endPositionId;
    map['startLat'] = _startLat;
    map['startLon'] = _startLon;
    map['endLat'] = _endLat;
    map['endLon'] = _endLon;
    map['startAddress'] = _startAddress;
    map['endAddress'] = _endAddress;
    map['duration'] = _duration;
    map['driverUniqueId'] = _driverUniqueId;
    map['driverName'] = _driverName;
    return map;
  }
}
