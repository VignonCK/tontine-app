package com.tontine.exception;

/**
 * Levée par un service quand une règle de gestion est violée
 * (ex. : « Ce membre a déjà cotisé pour ce tour. »).
 * Le message est en français et sera affiché tel quel à l'utilisateur.
 *
 * Pourquoi RuntimeException (exception non vérifiée) ?
 * - pas besoin de déclarer « throws » sur chaque méthode de la chaîne
 *   contrôleur → service → dépôt ;
 * - Spring annule automatiquement une transaction @Transactional
 *   sur une RuntimeException (pas sur une exception vérifiée, par défaut).
 */
public class RegleMetierException extends RuntimeException {

    public RegleMetierException(String message) {
        super(message);
    }
}
