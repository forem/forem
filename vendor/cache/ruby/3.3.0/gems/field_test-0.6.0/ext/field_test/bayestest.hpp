/*!
 * BayesTest C++ v0.1.0
 * https://github.com/ankane/bayestest-cpp
 * MIT License
 */

#pragma once

#include <cmath>
#include <vector>

namespace bayestest {

double logbeta(double a, double b) {
  return std::lgamma(a) + std::lgamma(b) - std::lgamma(a + b);
}

double prob_b_beats_a(int alpha_a, int beta_a, int alpha_b, int beta_b) {
  double total = 0.0;
  double logbeta_aa_ba = logbeta(alpha_a, beta_a);
  double beta_ba = beta_b + beta_a;

  for (auto i = 0; i < alpha_b; i++) {
    total += exp(logbeta(alpha_a + i, beta_ba) - log(beta_b + i) - logbeta(1 + i, beta_b) - logbeta_aa_ba);
  }

  return total;
}

double prob_c_beats_ab(int alpha_a, int beta_a, int alpha_b, int beta_b, int alpha_c, int beta_c) {
  double total = 0.0;

  double logbeta_ac_bc = logbeta(alpha_c, beta_c);

  std::vector<double> log_bb_j_logbeta_j_bb;
  log_bb_j_logbeta_j_bb.reserve(alpha_b);

  for (auto j = 0; j < alpha_b; j++) {
    log_bb_j_logbeta_j_bb.push_back(log(beta_b + j) + logbeta(1 + j, beta_b));
  }

  double abc = beta_a + beta_b + beta_c;
  std::vector<double> logbeta_ac_i_j;
  logbeta_ac_i_j.reserve(alpha_a + alpha_b);

  for (auto i = 0; i < alpha_a + alpha_b; i++) {
    logbeta_ac_i_j.push_back(logbeta(alpha_c + i, abc));
  }

  for (auto i = 0; i < alpha_a; i++) {
    double sum_i = -log(beta_a + i) - logbeta(1 + i, beta_a) - logbeta_ac_bc;

    for (auto j = 0; j < alpha_b; j++) {
      total += exp(sum_i + logbeta_ac_i_j[i + j] - log_bb_j_logbeta_j_bb[j]);
    }
  }

  return 1 - prob_b_beats_a(alpha_c, beta_c, alpha_a, beta_a) -
    prob_b_beats_a(alpha_c, beta_c, alpha_b, beta_b) + total;
}

double prob_d_beats_abc(int alpha_a, int beta_a, int alpha_b, int beta_b, int alpha_c, int beta_c, int alpha_d, int beta_d) {
  double total = 0.0;

  double logbeta_ad_bd = logbeta(alpha_d, beta_d);

  std::vector<double> log_bb_j_logbeta_j_bb;
  log_bb_j_logbeta_j_bb.reserve(alpha_b);

  for (auto j = 0; j < alpha_b; j++) {
    log_bb_j_logbeta_j_bb.push_back(log(beta_b + j) + logbeta(1 + j, beta_b));
  }

  std::vector<double> log_bc_k_logbeta_k_bc;
  log_bc_k_logbeta_k_bc.reserve(alpha_c);

  for (auto k = 0; k < alpha_c; k++) {
    log_bc_k_logbeta_k_bc.push_back(log(beta_c + k) + logbeta(1 + k, beta_c));
  }

  double abcd = beta_a + beta_b + beta_c + beta_d;
  std::vector<double> logbeta_bd_i_j_k;
  logbeta_bd_i_j_k.reserve(alpha_a + alpha_b + alpha_c);

  for (auto i = 0; i < alpha_a + alpha_b + alpha_c; i++) {
    logbeta_bd_i_j_k.push_back(logbeta(alpha_d + i, abcd));
  }

  for (auto i = 0; i < alpha_a; i++) {
    double sum_i = -log(beta_a + i) - logbeta(1 + i, beta_a) - logbeta_ad_bd;

    for (auto j = 0; j < alpha_b; j++) {
      double sum_j = sum_i - log_bb_j_logbeta_j_bb[j];

      for (auto k = 0; k < alpha_c; k++) {
        total += exp(sum_j + logbeta_bd_i_j_k[i + j + k] - log_bc_k_logbeta_k_bc[k]);
      }
    }
  }

  return 1 - prob_b_beats_a(alpha_a, beta_a, alpha_d, beta_d) -
    prob_b_beats_a(alpha_b, beta_b, alpha_d, beta_d) -
    prob_b_beats_a(alpha_c, beta_c, alpha_d, beta_d) +
    prob_c_beats_ab(alpha_a, beta_a, alpha_b, beta_b, alpha_d, beta_d) +
    prob_c_beats_ab(alpha_a, beta_a, alpha_c, beta_c, alpha_d, beta_d) +
    prob_c_beats_ab(alpha_b, beta_b, alpha_c, beta_c, alpha_d, beta_d) - total;
}

double prob_1_beats_2(int alpha_1, int beta_1, int alpha_2, int beta_2) {
  double total = 0.0;
  double log_b1 = log(beta_1);
  double a2_log_b2 = alpha_2 * log(beta_2);
  double log_b1_b2 = log(beta_1 + beta_2);

  for (auto k = 0; k < alpha_1; k++) {
    total += exp(k * log_b1 +
      a2_log_b2 -
      (k + alpha_2) * log_b1_b2 -
      log(k + alpha_2) -
      logbeta(k + 1, alpha_2));
  }

  return total;
}

double prob_1_beats_23(int alpha_1, int beta_1, int alpha_2, int beta_2, int alpha_3, int beta_3) {
  double total = 0.0;

  double log_b1_b2_b3 = log(beta_1 + beta_2 + beta_3);
  double a1_log_b1 = alpha_1 * log(beta_1);
  double log_b2 = log(beta_2);
  double log_b3 = log(beta_3);
  double loggamma_a1 = std::lgamma(alpha_1);

  for (auto k = 0; k < alpha_2; k++) {
    double sum_k = a1_log_b1 + k * log_b2 - std::lgamma(k + 1);

    for (auto l = 0; l < alpha_3; l++) {
      total += exp(sum_k + l * log_b3
        - (k + l + alpha_1) * log_b1_b2_b3
        + std::lgamma(k + l + alpha_1) - std::lgamma(l + 1) - loggamma_a1);
    }
  }

  return 1.0 - prob_1_beats_2(alpha_2, beta_2, alpha_1, beta_1)
    - prob_1_beats_2(alpha_3, beta_3, alpha_1, beta_1) + total;
}

class BinaryTest {
public:
  void add(int participants, int conversions) {
    variants.emplace_back(participants, conversions);
  }

  std::vector<double> probabilities() {
    std::vector<double> probs;
    probs.reserve(variants.size());

    switch (variants.size()) {
      case 0: {
        break;
      }
      case 1: {
        probs.push_back(1);

        break;
      }
      case 2: {
        auto b = variants[0];
        auto a = variants[1];

        auto prob = prob_b_beats_a(
          1 + a.conversions,
          1 + a.participants - a.conversions,
          1 + b.conversions,
          1 + b.participants - b.conversions
        );
        probs.push_back(prob);
        probs.push_back(1 - prob);

        break;
      }
      case 3: {
        auto total = 0.0;
        for (auto i = 0; i < 2; i++) {
            auto c = variants[i];
            auto b = variants[(i + 1) % 3];
            auto a = variants[(i + 2) % 3];

            auto prob = prob_c_beats_ab(
              1 + a.conversions,
              1 + a.participants - a.conversions,
              1 + b.conversions,
              1 + b.participants - b.conversions,
              1 + c.conversions,
              1 + c.participants - c.conversions
            );

            probs.push_back(prob);
            total += prob;
        }
        probs.push_back(1 - total);

        break;
      }
      default: {
        auto total = 0.0;
        for (auto i = 0; i < 3; i++) {
            auto d = variants[i];
            auto c = variants[(i + 1) % 4];
            auto b = variants[(i + 2) % 4];
            auto a = variants[(i + 3) % 4];

            auto prob = prob_d_beats_abc(
              1 + a.conversions,
              1 + a.participants - a.conversions,
              1 + b.conversions,
              1 + b.participants - b.conversions,
              1 + c.conversions,
              1 + c.participants - c.conversions,
              1 + d.conversions,
              1 + d.participants - d.conversions
            );

            probs.push_back(prob);
            total += prob;
        }
        probs.push_back(1 - total);
      }
    }
    return probs;
  }

private:
  struct Variant {
    Variant(int participants, int conversions) : participants(participants), conversions(conversions) {};
    int participants;
    int conversions;
  };

  std::vector<Variant> variants;
};

class CountTest {
public:
  void add(int events, int exposure) {
    variants.emplace_back(events, exposure);
  }

  std::vector<double> probabilities() {
    std::vector<double> probs;
    probs.reserve(variants.size());

    switch (variants.size()) {
      case 0: {
        break;
      }
      case 1: {
        probs.push_back(1);

        break;
      }
      case 2: {
        auto a = variants[0];
        auto b = variants[1];

        auto prob = prob_1_beats_2(
          a.events,
          a.exposure,
          b.events,
          b.exposure
        );
        probs.push_back(prob);
        probs.push_back(1 - prob);

        break;
      }
      default: {
        auto total = 0.0;
        for (auto i = 0; i < 2; i++) {
            auto a = variants[i];
            auto b = variants[(i + 1) % 3];
            auto c = variants[(i + 2) % 3];

            auto prob = prob_1_beats_23(
              a.events,
              a.exposure,
              b.events,
              b.exposure,
              c.events,
              c.exposure
            );

            probs.push_back(prob);
            total += prob;
        }
        probs.push_back(1 - total);
      }
    }
    return probs;
  }

private:
  struct Variant {
    Variant(int events, int exposure) : events(events), exposure(exposure) {};
    int events;
    int exposure;
  };

  std::vector<Variant> variants;
};

}
