// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      phoneNumber: fields[2] as String,
      email: fields[3] as String?,
      age: fields[4] as int?,
      weight: fields[5] as double?,
      height: fields[6] as int?,
      gender: fields[7] as String?,
      workoutFrequency: fields[8] as int?,
      workoutLocation: fields[9] as String?,
      experienceLevel: fields[10] as String?,
      mainGoal: fields[11] as String?,
      injuries: (fields[12] as List).cast<String>(),
      subscriptionTier: fields[13] as String,
      coachId: fields[14] as String?,
      hasCompletedFirstIntake: fields[15] as bool,
      hasCompletedSecondIntake: fields[16] as bool,
      fitnessScore: fields[17] as int?,
      fitnessScoreUpdatedBy: fields[18] as String?,
      fitnessScoreLastUpdated: fields[19] as DateTime?,
      role: fields[20] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.age)
      ..writeByte(5)
      ..write(obj.weight)
      ..writeByte(6)
      ..write(obj.height)
      ..writeByte(7)
      ..write(obj.gender)
      ..writeByte(8)
      ..write(obj.workoutFrequency)
      ..writeByte(9)
      ..write(obj.workoutLocation)
      ..writeByte(10)
      ..write(obj.experienceLevel)
      ..writeByte(11)
      ..write(obj.mainGoal)
      ..writeByte(12)
      ..write(obj.injuries)
      ..writeByte(13)
      ..write(obj.subscriptionTier)
      ..writeByte(14)
      ..write(obj.coachId)
      ..writeByte(15)
      ..write(obj.hasCompletedFirstIntake)
      ..writeByte(16)
      ..write(obj.hasCompletedSecondIntake)
      ..writeByte(17)
      ..write(obj.fitnessScore)
      ..writeByte(18)
      ..write(obj.fitnessScoreUpdatedBy)
      ..writeByte(19)
      ..write(obj.fitnessScoreLastUpdated)
      ..writeByte(20)
      ..write(obj.role);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
