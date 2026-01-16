import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Simple profile model persisted in the local SQLite DB.
class LocalProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final String? bio;
  final String? photoUrl;
  final String? location;
  final String? phone;
  final String? website;
  final DateTime updatedAt;

  const LocalProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.bio,
    this.photoUrl,
    this.location,
    this.phone,
    this.website,
    required this.updatedAt,
  });

  LocalProfile copyWith({
    String? displayName,
    String? email,
    String? bio,
    String? photoUrl,
    String? location,
    String? phone,
    String? website,
    DateTime? updatedAt,
  }) {
    return LocalProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'display_name': displayName,
      'email': email,
      'bio': bio,
      'photo_url': photoUrl,
      'location': location,
      'phone': phone,
      'website': website,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static LocalProfile fromMap(Map<String, dynamic> map) {
    return LocalProfile(
      uid: map['uid'] as String,
      displayName: map['display_name'] as String?,
      email: map['email'] as String?,
      bio: map['bio'] as String?,
      photoUrl: map['photo_url'] as String?,
      location: map['location'] as String?,
      phone: map['phone'] as String?,
      website: map['website'] as String?,
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Handles on-device persistence only (no cloud writes).
class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  Database? _db;

  /// Initialize the local DB once; safe to call multiple times.
  Future<void> init() async {
    if (_db != null) return;
    // Web has no sqflite implementation; fall back to in-memory (no-op) storage.
    if (kIsWeb) {
      _db = null;
      return;
    }
    final basePath = await getDatabasesPath();
    final dbPath = p.join(basePath, 'green_getaway.db');
    _db = await openDatabase(
      dbPath,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profiles (
            uid TEXT PRIMARY KEY,
            display_name TEXT,
            email TEXT,
            bio TEXT,
            photo_url TEXT,
            location TEXT,
            phone TEXT,
            website TEXT,
            updated_at TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uid TEXT,
            title TEXT,
            subtitle TEXT,
            location TEXT,
            price TEXT,
            image_url TEXT,
            asset_path TEXT,
            date_iso TEXT,
            is_past INTEGER,
            UNIQUE(uid, title, location)
          );
        ''');
        await db.execute('''
          CREATE TABLE saved_activities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uid TEXT,
            title TEXT,
            subtitle TEXT,
            location TEXT,
            price TEXT,
            image_url TEXT,
            asset_path TEXT,
            date_iso TEXT,
            is_past INTEGER,
            UNIQUE(uid, title, location)
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE profiles ADD COLUMN location TEXT;');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE profiles ADD COLUMN phone TEXT;');
          await db.execute('ALTER TABLE profiles ADD COLUMN website TEXT;');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE trips (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              uid TEXT,
              title TEXT,
              subtitle TEXT,
              location TEXT,
              price TEXT,
              image_url TEXT,
              asset_path TEXT,
              date_iso TEXT,
              is_past INTEGER,
              UNIQUE(uid, title, location)
            );
          ''');
          await db.execute('''
            CREATE TABLE saved_activities (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              uid TEXT,
              title TEXT,
              subtitle TEXT,
              location TEXT,
              price TEXT,
              image_url TEXT,
              asset_path TEXT,
              date_iso TEXT,
              is_past INTEGER,
              UNIQUE(uid, title, location)
            );
          ''');
        }
      },
    );
  }

  Future<LocalProfile?> getProfile(String uid) async {
    final db = _db;
    if (db == null) return null;
    final rows = await db.query(
      'profiles',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LocalProfile.fromMap(rows.first);
  }

  Future<void> upsertProfile(LocalProfile profile) async {
    final db = _db;
    if (db == null) return;
    // Replace-or-insert to keep a single row per user.
    await db.insert(
      'profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save an activity/trip locally; [saved] chooses table (saved vs history).
  Future<void> upsertTrip({
    required String uid,
    required Map<String, dynamic> data,
    required bool saved,
  }) async {
    final db = _db;
    if (db == null) return;
    final table = saved ? 'saved_activities' : 'trips';
    await db.insert(
      table,
      {'uid': uid, ...data},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSavedActivity({
    required String uid,
    required String title,
    required String location,
  }) async {
    // Remove a saved activity for a specific user and location.
    final db = _db;
    if (db == null) return;
    await db.delete(
      'saved_activities',
      where: 'uid = ? AND title = ? AND location = ?',
      whereArgs: [uid, title, location],
    );
  }

  Future<void> deleteTrip({
    required String uid,
    required String title,
    required String location,
  }) async {
    // Remove a booked trip for a specific user and location.
    final db = _db;
    if (db == null) return;
    await db.delete(
      'trips',
      where: 'uid = ? AND title = ? AND location = ?',
      whereArgs: [uid, title, location],
    );
  }

  Future<List<Map<String, dynamic>>> getTrips({
    required String uid,
    required bool saved,
  }) async {
    // Fetch saved or history entries ordered by newest date first.
    final db = _db;
    if (db == null) return [];
    final table = saved ? 'saved_activities' : 'trips';
    final rows = await db.query(
      table,
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'date_iso DESC',
    );
    return rows;
  }
}
