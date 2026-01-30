# frozen_string_literal: true

class IssueViewColumnsRelationsController < ApplicationController
  before_action :find_issues, :authorize_manage_relations, only: :create
  before_action :find_relation, only: :destroy

  def create
    issue_ids = @issues.map(&:id)
    existing_pairs = IssueRelation.where(
      issue_from_id: issue_ids,
      issue_to_id: issue_ids,
      relation_type: IssueRelation::TYPE_RELATES
    ).pluck(:issue_from_id, :issue_to_id).each_with_object({}) do |pair, memo|
      memo[pair.sort] = true
    end

    unsaved_relations = []

    @issues.combination(2) do |issue_from, issue_to|
      pair = [issue_from.id, issue_to.id].sort
      next if existing_pairs[pair]

      relation = IssueRelation.new(
        issue_from: issue_from,
        issue_to: issue_to,
        relation_type: IssueRelation::TYPE_RELATES
      )
      relation.init_journals(User.current)

      begin
        saved = relation.save
      rescue ActiveRecord::RecordNotUnique
        relation.errors.add :base, :taken
        saved = false
      end

      unsaved_relations << relation unless saved
    end

    if unsaved_relations.any?
      flash[:error] = unsaved_relations.flat_map { |relation| relation.errors.full_messages }.uniq.join(', ')
    end

    redirect_back_or_default(issues_path)
  end

  def destroy
    raise Unauthorized unless @relation.deletable?

    @relation.init_journals(User.current)
    @relation.destroy

    redirect_back_or_default(issues_path)
  end

  private

  def authorize_manage_relations
    return if @issues.all? { |issue| User.current.allowed_to?(:manage_issue_relations, issue.project) }

    raise Unauthorized
  end

  def find_relation
    @relation = IssueRelation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
