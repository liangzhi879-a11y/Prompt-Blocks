"""TestResultModel — QAbstractListModel for test results."""

from PySide6.QtCore import Qt, QAbstractListModel, QModelIndex, Slot, Signal


class TestResultModel(QAbstractListModel):
    """QAbstractListModel managing test results with scoring."""

    InputTextRole = Qt.ItemDataRole.UserRole + 1
    OutputTextRole = Qt.ItemDataRole.UserRole + 2
    ContentScoreRole = Qt.ItemDataRole.UserRole + 3
    FormatScoreRole = Qt.ItemDataRole.UserRole + 4
    SafetyScoreRole = Qt.ItemDataRole.UserRole + 5
    IsPassedRole = Qt.ItemDataRole.UserRole + 6

    resultsChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._results = []  # list of dicts

    def rowCount(self, parent=QModelIndex()):
        return len(self._results)

    def data(self, index, role=Qt.ItemDataRole.DisplayRole):
        if not index.isValid() or index.row() >= len(self._results):
            return None
        result = self._results[index.row()]
        role_map = {
            self.InputTextRole: "inputText",
            self.OutputTextRole: "outputText",
            self.ContentScoreRole: "contentScore",
            self.FormatScoreRole: "formatScore",
            self.SafetyScoreRole: "safetyScore",
            self.IsPassedRole: "isPassed",
        }
        key = role_map.get(role)
        if key is not None:
            return result.get(key)
        return None

    def roleNames(self):
        return {
            self.InputTextRole: b'inputText',
            self.OutputTextRole: b'outputText',
            self.ContentScoreRole: b'contentScore',
            self.FormatScoreRole: b'formatScore',
            self.SafetyScoreRole: b'safetyScore',
            self.IsPassedRole: b'isPassed',
        }

    @Slot(str, str, float, float, float)
    def addResult(self, inputText, outputText, contentScore, formatScore, safetyScore):
        """Add a test result with scores."""
        is_passed = contentScore >= 6.0 and formatScore >= 6.0 and safetyScore >= 6.0
        result = {
            "inputText": inputText,
            "outputText": outputText,
            "contentScore": contentScore,
            "formatScore": formatScore,
            "safetyScore": safetyScore,
            "isPassed": is_passed,
        }

        row = len(self._results)
        self.beginInsertRows(QModelIndex(), row, row)
        self._results.append(result)
        self.endInsertRows()
        self.resultsChanged.emit()

    @Slot()
    def clearResults(self):
        """Remove all test results."""
        if not self._results:
            return
        self.beginRemoveRows(QModelIndex(), 0, len(self._results) - 1)
        self._results.clear()
        self.endRemoveRows()
        self.resultsChanged.emit()

    @Slot(result="QVariantMap")
    def getStatistics(self):
        """Return aggregate statistics: averages, pass rate, count."""
        if not self._results:
            return {
                "count": 0,
                "avgContent": 0.0,
                "avgFormat": 0.0,
                "avgSafety": 0.0,
                "passRate": 0.0,
            }

        n = len(self._results)
        total_content = sum(r["contentScore"] for r in self._results)
        total_format = sum(r["formatScore"] for r in self._results)
        total_safety = sum(r["safetyScore"] for r in self._results)
        passed = sum(1 for r in self._results if r["isPassed"])

        return {
            "count": n,
            "avgContent": round(total_content / n, 2),
            "avgFormat": round(total_format / n, 2),
            "avgSafety": round(total_safety / n, 2),
            "passRate": round(passed / n * 100, 1),
        }
