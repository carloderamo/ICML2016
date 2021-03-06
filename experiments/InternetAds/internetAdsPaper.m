%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script aims to replicate the internet ads   %
% experiments presented in H. V. Hasselt's article %
% "Estimating the Maximum Expected Value: An       %
% Analysis of (Nested) Cross Validation and the    %
% Maximum Sample Average".                         %
%                                                  %
% Written by: Carlo D'Eramo                        %
%                                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;

n_experiments = 2000;
n_actions = 30;
n_visitors = 3e5;
n_trials = n_visitors / n_actions;
error = zeros(n_experiments, 4);

idxs = repmat(1:n_actions, n_actions, 1);
idxs = (1 - eye(n_actions)) .* idxs';
idxs(idxs == 0) = [];
idxs = reshape(idxs, n_actions - 1, n_actions);
idxs = idxs';

for experiment = 1:n_experiments

    fprintf('Experiment: %d\n', experiment);

	if n_visitors == 1e5
		p(1, 1:n_actions) = 0.5;
	else
		p(1, 1:n_actions) = 0.02 + (0.05 - 0.02) * rand(1, n_actions);
	end

    [clicks, means, sigma] = crtLearning(n_actions, n_trials, p);

    % Maximum Estimator
    error(experiment, 1) = max(sum(clicks) / n_trials) - max(p);
    
    % Double Estimator
    clicks1 = clicks(1:n_trials / 2, :);
    clicks2 = clicks(n_trials / 2 + 1:end, :);
    pHat1 = sum(clicks1) / (n_trials / 2);
    pHat2 = sum(clicks2) / (n_trials / 2);
    doubleAdMax = find(pHat1 == max(pHat1));
    mu1 = mean(pHat2(doubleAdMax));
    
    doubleAdMax = find(pHat2 == max(pHat2));
    mu2 = mean(pHat1(doubleAdMax));
    error(experiment, 2) = mean([mu1 mu2]) - max(p);
    
    % Maxmin Estimator
    clicks1 = clicks(1:n_trials / 2, :);
    clicks2 = clicks(n_trials / 2 + 1:end, :);
    pHat1 = sum(clicks1) / (n_trials / 2);
    pHat2 = sum(clicks2) / (n_trials / 2);
    pmin = min(pHat1, pHat2);
    error(experiment, 3) = max(pmin) - max(p);
    
%         % W Estimator
%         lower_limit = means - 8 * sigma;
%         upper_limit = means + 8 * sigma;
%         n_trapz = 2e2;
%         x = zeros(n_trapz, n_actions);
%         y = zeros(size(x));
%         for j = 1:n_actions
%             x(:, j) = linspace(lower_limit(j), upper_limit(j), n_trapz);
%             y(:, j) = normpdf(x(:, j), means(j), sigma(j)) .* ...
%                     prod(normcdf(repmat(x(:, j), 1, n_actions - 1), ...
%                                  means(repmat(idxs(j, :), n_trapz, 1)), ...
%                                  sigma(repmat(idxs(j, :), n_trapz, 1))), 2);
%         end
%         integrals = trapz(y, 1) .* ((upper_limit - lower_limit) / (n_trapz - 1));
%         error(experiment, 4, i) = integrals * means' - max(p);
        n_samples = 1000;
        samples = repmat(means, n_samples, 1) + repmat(sigma, n_samples, 1) .* randn(n_samples, n_actions(i));
        [~, max_idxs] = max(samples');
        max_count = zeros(size(samples));
        max_count(sub2ind(size(samples), 1:length(max_idxs'), max_idxs)) = 1;

        probs = sum(max_count, 1) / n_samples;
        error(experiment, 4, i) = probs * means' - max(p);
end

bias = mean(error);
variance = var(error);

rmse = sqrt(bias.^2 + variance);

n_actions_text = num2str(n_actions);
save(strcat('internetAds-', n_actions_text,'.mat'));

