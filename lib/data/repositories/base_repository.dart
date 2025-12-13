import 'package:logging/logging.dart';

/// Base repository interface for data access operations.
///
/// This interface defines the standard CRUD operations and sync-related
/// methods that all repositories must implement. It provides a consistent
/// API for accessing data regardless of whether it's stored locally or
/// retrieved from the server.
///
/// Type parameter [T] represents the entity type (e.g., Transaction, Account).
/// Type parameter [ID] represents the identifier type (typically String).
abstract class BaseRepository<T, ID> {
  /// Logger instance for the repository.
  Logger get logger;

  /// Retrieves all entities.
  ///
  /// Returns a list of all entities. In offline mode, returns locally stored
  /// entities. In online mode, fetches from the server and updates local cache.
  ///
  /// Throws [DatabaseException] if local database access fails.
  /// Throws [ConnectivityException] if online mode and server is unreachable.
  Future<List<T>> getAll();

  /// Retrieves a stream of all entities.
  ///
  /// Returns a stream that emits the current list of entities and updates
  /// whenever the data changes. Useful for reactive UI updates.
  Stream<List<T>> watchAll();

  /// Retrieves an entity by its ID.
  ///
  /// Returns the entity with the given [id], or null if not found.
  ///
  /// Throws [DatabaseException] if local database access fails.
  /// Throws [ConnectivityException] if online mode and server is unreachable.
  Future<T?> getById(ID id);

  /// Retrieves a stream of an entity by its ID.
  ///
  /// Returns a stream that emits the entity and updates whenever it changes.
  Stream<T?> watchById(ID id);

  /// Creates a new entity.
  ///
  /// In offline mode, stores the entity locally and adds to sync queue.
  /// In online mode, creates on the server and updates local cache.
  ///
  /// Returns the created entity with its assigned ID.
  ///
  /// Throws [ValidationException] if entity data is invalid.
  /// Throws [DatabaseException] if local storage fails.
  /// Throws [SyncException] if online mode and server creation fails.
  Future<T> create(T entity);

  /// Updates an existing entity.
  ///
  /// In offline mode, updates locally and adds to sync queue.
  /// In online mode, updates on the server and updates local cache.
  ///
  /// Returns the updated entity.
  ///
  /// Throws [ValidationException] if entity data is invalid.
  /// Throws [DatabaseException] if local storage fails.
  /// Throws [SyncException] if online mode and server update fails.
  Future<T> update(ID id, T entity);

  /// Deletes an entity by its ID.
  ///
  /// In offline mode, marks as deleted locally and adds to sync queue.
  /// In online mode, deletes from the server and removes from local cache.
  ///
  /// Throws [DatabaseException] if local storage fails.
  /// Throws [SyncException] if online mode and server deletion fails.
  Future<void> delete(ID id);

  /// Retrieves all entities that haven't been synced with the server.
  ///
  /// Returns a list of entities where [isSynced] is false.
  /// Used by the sync manager to determine what needs to be synchronized.
  Future<List<T>> getUnsynced();

  /// Marks an entity as synced with the server.
  ///
  /// Updates the entity's sync status and stores the server-assigned ID.
  /// Called by the sync manager after successful synchronization.
  ///
  /// [localId] - The local ID of the entity.
  /// [serverId] - The server-assigned ID.
  Future<void> markAsSynced(ID localId, String serverId);

  /// Gets the sync status of an entity.
  ///
  /// Returns the current sync status: 'pending', 'syncing', 'synced', or 'error'.
  Future<String> getSyncStatus(ID id);

  /// Clears all locally cached data.
  ///
  /// Removes all entities from local storage. Use with caution.
  /// Typically called when logging out or resetting the app.
  Future<void> clearCache();

  /// Gets the count of entities.
  ///
  /// Returns the total number of entities stored locally.
  Future<int> count();
}
