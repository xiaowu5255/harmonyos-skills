## 📊 Evals 报告（v0.7.0 自进化硬化）

**报告日期**：{{ report_date }}
**总条数**：{{ summary.total }}
**Machine 通过率**：{{ summary.machine_passed }} / {{ summary.machine_total }}
**Semantic 等待人工 review**：{{ summary.semantic_count }}

### 按 Skill 趋势

| Skill | Machine 总 | 通过 | 失败 | 待人工 |
|-------|-----------|------|------|--------|
{%- for skill, s in summary.by_skill.items() %}
| {{ skill }} | {{ s.machine_total }} | {{ s.machine_pass }} | {{ s.machine_fail }} | {{ s.semantic_count }} |
{%- endfor %}

> 📈 与上一次报告对比：{{ trend_note }}
> 🔍 报告原文：`tools/evals/reports/{{ report_date }}.json`（CI artifact）
> ⚠️ 本 job 默认 `continue-on-error: true`，不阻断合并
