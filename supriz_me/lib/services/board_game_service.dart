import 'package:hive/hive.dart';
import '../models/board_game.dart';

class BoardGameService {
  final Box<BoardGame> _boardGameBox;

  BoardGameService(this._boardGameBox);

  /// Ajoute un jeu de société à la base de données
  Future<void> addBoardGame(BoardGame boardGame) async {
    await _boardGameBox.put(boardGame.id, boardGame);
  }

  /// Récupère tous les jeux de société
  List<BoardGame> getAllBoardGames() {
    return _boardGameBox.values.toList();
  }

  /// Récupère un jeu par ID
  BoardGame? getBoardGameById(String id) {
    return _boardGameBox.get(id);
  }

  /// Supprime un jeu
  Future<void> deleteBoardGame(String id) async {
    await _boardGameBox.delete(id);
  }

  /// Récupère les jeux adaptés à un nombre de joueurs
  List<BoardGame> getGamesByPlayerCount(int playerCount) {
    return _boardGameBox.values
        .where((game) => game.minPlayers <= playerCount && game.maxPlayers >= playerCount)
        .toList();
  }

  /// Récupère les jeux triés par complexité
  List<BoardGame> getGamesByComplexity(double maxComplexity) {
    return _boardGameBox.values
        .where((game) => game.complexity <= maxComplexity)
        .toList();
  }
}
