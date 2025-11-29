```mermaid
classDiagram
  direction LR

  %% Navigation shell
  namespace Navigation {
    class BottomNav {
      -_index
      -_exploreQuery?
      -_trips
      -_savedActivities
      <<shell>>
    }
  }

  %% Screens / UI flows
  namespace Screens {
    class HomePage
    class ExplorePage {
      +savedKeys
      +bookedKeys
      +onToggleSave
      +onBookStay
      +onJoinTrip?
    }
    class TripsPage {
      +trips
      +savedActivities
    }
    class ProfilePage
    class AuthRequiredPage
    class SignInPage
    class SignUpPage
    class ActivityDetailPage {
      +entry
      +tagPrimary
      +tagSecondary
    }
    class EventDetailPage {
      +onJoin
    }
    class LocationDetailPage {
      +location
      +isSaved
      +isBooked
    }
  }

  %% Data / persistence
  namespace Data {
    class LocalDb {
      +init()
      +getProfile(uid)
      +upsertProfile(profile)
      +upsertTrip(uid,data,saved)
      +deleteSavedActivity(uid,title,location)
      +getTrips(uid,saved)
      <<repository>>
    }
  }

  %% Domain models
  namespace Models {
    class TripEntry {
      +title
      +subtitle
      +location
      +price
      +assetPath?
      +imageUrl?
      +date?
      +isPast
    }
    class LocalProfile {
      +uid
      +displayName?
      +email?
      +bio?
      +photoUrl?
      +location?
      +phone?
      +website?
      +updatedAt
    }
    class EcoLocation
  }

  %% External services (conceptual)
  class FirebaseAuth <<external>>

  %% Navigation relationships
  BottomNav --> HomePage : navigates
  BottomNav --> ExplorePage : navigates
  BottomNav --> TripsPage : navigates
  BottomNav --> ProfilePage : navigates
  BottomNav --> AuthRequiredPage : routes when no auth

  %% Screen -> model dependencies (dashed = data flow / callbacks)
  HomePage ..> TripEntry : onJoinTrip callback
  ExplorePage ..> TripEntry : onJoinTrip callback
  ExplorePage ..> EcoLocation : lists/filters
  TripsPage --> TripEntry : displays
  ActivityDetailPage --> TripEntry : returns on join
  EventDetailPage ..> TripEntry : constructed for join
  LocationDetailPage ..> EcoLocation

  %% Auth/Profile flows
  SignInPage ..> LocalDb : ensure profile row
  SignUpPage ..> LocalDb : create profile row
  SignInPage ..> FirebaseAuth
  SignUpPage ..> FirebaseAuth
  AuthRequiredPage ..> FirebaseAuth

  %% Persistence links
  LocalDb --> LocalProfile "0..*" : persists profiles
  LocalDb --> TripEntry "0..*" : persists trips/saves
  LocalDb --> EcoLocation : used for saved/location detail
```

Notes:
- Grouped by Navigation, Screens, Data, Models to make structure easier to scan.
- Dashed arrows represent data/callback dependencies; solid arrows represent navigation/containment.
- External dependency `FirebaseAuth` is included conceptually for auth flows.
- Render with any Mermaid viewer (VS Code preview, GitHub, or https://kroki.io). For online renderers, paste the block without the ``` fences.
