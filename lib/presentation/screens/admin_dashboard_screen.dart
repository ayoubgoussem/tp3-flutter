import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../business_logic/providers/quiz_provider.dart';
import '../../data/repositories/score_repository.dart';
import '../../data/models/score_model.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ScoreRepository _repository = ScoreRepository();
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Admin'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            FutureBuilder<Map<String, dynamic>>(
              future: _repository.getStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Erreur: ${snapshot.error}'),
                    ),
                  );
                }
                
                final stats = snapshot.data!;
                final totalQuizzes = stats['totalQuizzes'] as int;
                final averageScore = stats['averageScore'] as double;
                final uniqueUsers = stats['uniqueUsers'] as int;
                
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.quiz,
                            title: 'Total Quiz',
                            value: totalQuizzes.toString(),
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.star,
                            title: 'Score Moyen',
                            value: '${averageScore.toStringAsFixed(1)}%',
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.people,
                            title: 'Utilisateurs',
                            value: uniqueUsers.toString(),
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Consumer<QuizProvider>(
                            builder: (context, quizProvider, _) {
                              return FutureBuilder<List<String>>(
                                future: quizProvider.getAllThemes(),
                                builder: (context, themeSnapshot) {
                                  final themeCount = themeSnapshot.data?.length ?? 0;
                                  return _StatCard(
                                    icon: Icons.category,
                                    title: 'Thèmes',
                                    value: themeCount.toString(),
                                    color: Colors.purple,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Most popular favorite theme - Full width
            FutureBuilder<Map<String, dynamic>>(
              future: _repository.getMostPopularFavoriteTheme(),
              builder: (context, favSnapshot) {
                if (favSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                final favData = favSnapshot.data ?? {'theme': 'Aucun', 'count': 0};
                final themeName = favData['theme'] as String;
                final count = favData['count'] as int;
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.favorite, size: 32, color: Colors.pink),
                        const SizedBox(height: 8),
                        Text(
                          themeName,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thème Préféré le Plus Populaire',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count utilisateur${count > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Leaderboard
            Text(
              '🏆 Top 10 Scores',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<ScoreModel>>(
              future: _repository.getTopScores(limit: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Erreur: ${snapshot.error}'),
                    ),
                  );
                }
                
                final scores = snapshot.data ?? [];
                
                if (scores.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 48,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(height: 8),
                            const Text('Aucun score enregistré'),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: scores.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final score = scores[index];
                      final rank = index + 1;
                      
                      // Ranking display for top 3
                      String rankDisplay;
                      Color? rankColor;
                      if (rank == 1) {
                        rankDisplay = '#1';
                        rankColor = Colors.amber;
                      } else if (rank == 2) {
                        rankDisplay = '#2';
                        rankColor = Colors.grey[400];
                      } else if (rank == 3) {
                        rankDisplay = '#3';
                        rankColor = Colors.brown[300];
                      } else {
                        rankDisplay = '#$rank';
                        rankColor = null;
                      }
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: rankColor ?? theme.colorScheme.primaryContainer,
                          child: Text(
                            rankDisplay,
                            style: TextStyle(
                              color: rank <= 3 ? Colors.white : theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(score.userName),
                        subtitle: Text(score.theme),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              score.scoreDisplay,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              '${score.percentage.toStringAsFixed(0)}%',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Recent Activity
            Text(
              '🕐 Activité Récente',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<ScoreModel>>(
              stream: _repository.streamAllScores(limit: 15),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Erreur: ${snapshot.error}'),
                    ),
                  );
                }
                
                final scores = snapshot.data ?? [];
                
                if (scores.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(height: 8),
                            const Text('Aucune activité récente'),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: scores.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final score = scores[index];
                      final dateFormat = DateFormat('dd/MM à HH:mm');
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: score.percentage >= 50
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            score.percentage >= 50 ? Icons.check : Icons.close,
                            color: score.percentage >= 50
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                        title: Text(score.userName),
                        subtitle: Text(
                          '${score.theme} • ${dateFormat.format(score.completedAt)}',
                        ),
                        trailing: Text(
                          score.scoreDisplay,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: score.percentage >= 50
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ); 
              },
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
