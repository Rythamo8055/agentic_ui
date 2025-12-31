// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationSessionAdapter extends TypeAdapter<ConversationSession> {
  @override
  final int typeId = 0;

  @override
  ConversationSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationSession(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      title: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ConversationSession obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
