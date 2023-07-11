import logging
import sys

import torch
import torch.nn.functional as F
from scipy.stats.stats import pearsonr
from sklearn.metrics import average_precision_score

logging.basicConfig(
    format="[%(asctime)s] %(levelname)s:%(name)s: %(message)s",
    level="INFO",
    stream=sys.stdout,
)
logger = logging.getLogger(__name__)


class RSquared:
    def __init__(self):
        pass

    def __call__(self, preds: torch.tensor, targets: torch.tensor):
        y_mean = torch.mean(targets)
        ss_tot = torch.sum(torch.square(targets - y_mean))
        ss_res = torch.sum(torch.square(targets - preds))
        return 1 - ss_res / ss_tot


class PearsonCorr:
    def __init__(self):
        pass

    def __call__(self, burden, y):

        if len(burden.shape) > 1:  # was the burden computed for >1 genes
            corrs = []
            for i in range(burden.shape[1]):  # number of genes
                b = burden[:, i].squeeze()
                if len(b.unique()) <= 1:
                    corr = 0
                else:
                    corr = abs(pearsonr(b, y.squeeze())[0])
                corrs.append(corr)
            corr = sum(corrs)
            logger.info(f"correlation_sum: {corr}")
        else:
            corr = abs(pearsonr(burden.squeeze(), y.squeeze())[0])

        return corr


class PearsonCorrTorch:
    def __init__(self):
        pass

    def __call__(self, burden, y):

        if len(burden.shape) > 1:  # was the burden computed for >1 genes
            corrs = []
            for i in range(burden.shape[1]):  # number of genes
                b = burden[:, i].squeeze()
                if (
                    len(b.unique()) <= 1
                ):  # if all burden values are the same, correlation will be nan -> must be avoided
                    corr = torch.tensor(0)
                else:
                    corr = abs(self.calculate_pearsonr(b, y.squeeze()))
                corrs.append(corr)
            # corr = sum(corrs)
            corr = torch.stack(corrs).mean()
            logger.info(f"correlation_sum: {corr}")

        else:
            corr = abs(self.calculate_pearsonr(burden.squeeze(), y.squeeze()))

        return corr

    def calculate_pearsonr(self, x, y):

        vx = x - torch.mean(x)
        vy = y - torch.mean(y)

        corr = torch.sum(vx * vy) / (
            torch.sqrt(torch.sum(vx**2)) * torch.sqrt(torch.sum(vy**2))
        )
        return corr


class AveragePrecisionWithLogits:
    def __init__(self):
        pass

    def __call__(self, logits, y):
        y_scores = F.sigmoid(logits.detach())
        return average_precision_score(y.detach().cpu().numpy(), y_scores.cpu().numpy())