from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.http import HttpRequest, HttpResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.views.decorators.http import require_POST

from news.forms import CustomFeedForm, FollowUpAnswerForm
from news.models import (
    Article,
    Feed,
    FollowUpAnswer,
    FollowUpQuestion,
    RelevanceFeedback,
    Subscription,
)
from news.services import next_questions, rank_items, recommend_feeds


def landing(request: HttpRequest) -> HttpResponse:
    if request.user.is_authenticated:
        return redirect("brief")
    return render(request, "news/landing.html")


def oauth_popup_start(request: HttpRequest) -> HttpResponse:
    """Open this in the OAuth popup first (200 + session cookie), then go to Google.

    Opening ``/accounts/google/login/`` directly in a popup often drops the session
    cookie on the immediate 302 → Google, which breaks state/PKCE on callback.
    """
    if request.user.is_authenticated:
        return redirect("oauth_popup_done")
    request.session["oauth_popup"] = True
    request.session.save()
    return render(request, "news/oauth_popup_start.html")


@login_required
def oauth_popup_done(request: HttpRequest) -> HttpResponse:
    """Land here after Google OAuth in a popup; close popup and navigate opener."""
    request.session.pop("oauth_popup", None)
    return render(
        request,
        "news/oauth_popup_done.html",
        {"next_url": request.GET.get("next") or reverse("brief")},
    )


@login_required
def brief(request: HttpRequest) -> HttpResponse:
    ranked = rank_items(request.user)
    pending_questions = next_questions(request.user, limit=1)
    return render(
        request,
        "news/brief.html",
        {
            "ranked": ranked,
            "pending_question": pending_questions[0] if pending_questions else None,
            "subscription_count": Subscription.objects.filter(user=request.user).count(),
        },
    )


@login_required
def feeds(request: HttpRequest) -> HttpResponse:
    subscribed_ids = set(
        Subscription.objects.filter(user=request.user).values_list("feed_id", flat=True)
    )
    catalog = Feed.objects.filter(
        is_active=True,
        kind__in=[Feed.SourceKind.CURATED, Feed.SourceKind.RECOMMENDED],
        owner__isnull=True,
    )
    custom = Feed.objects.filter(owner=request.user, is_active=True)
    recommended = recommend_feeds(request.user)
    form = CustomFeedForm()

    if request.method == "POST" and "add_custom" in request.POST:
        form = CustomFeedForm(request.POST)
        if form.is_valid():
            feed = Feed.objects.create(
                title=form.cleaned_data["title"],
                url=form.cleaned_data["url"],
                site_url=form.cleaned_data.get("site_url") or "",
                description=form.cleaned_data.get("description") or "",
                category=form.cleaned_data.get("category") or "Custom",
                kind=Feed.SourceKind.CUSTOM,
                owner=request.user,
            )
            Subscription.objects.get_or_create(user=request.user, feed=feed)
            messages.success(request, f"Added and subscribed to “{feed.title}”.")
            return redirect("feeds")

    return render(
        request,
        "news/feeds.html",
        {
            "catalog": catalog,
            "custom_feeds": custom,
            "recommended": recommended,
            "subscribed_ids": subscribed_ids,
            "form": form,
        },
    )


@login_required
@require_POST
def subscribe(request: HttpRequest, feed_id: int) -> HttpResponse:
    feed = get_object_or_404(Feed, pk=feed_id, is_active=True)
    if feed.owner_id and feed.owner_id != request.user.id:
        messages.error(request, "That feed is private to another user.")
        return redirect("feeds")
    Subscription.objects.get_or_create(user=request.user, feed=feed)
    messages.success(request, f"Subscribed to {feed.title}.")
    return redirect(request.POST.get("next") or "feeds")


@login_required
@require_POST
def unsubscribe(request: HttpRequest, feed_id: int) -> HttpResponse:
    Subscription.objects.filter(user=request.user, feed_id=feed_id).delete()
    messages.info(request, "Unsubscribed.")
    return redirect(request.POST.get("next") or "feeds")


@login_required
@require_POST
def feedback(request: HttpRequest, article_id: int) -> HttpResponse:
    article = get_object_or_404(Article, pk=article_id)
    verdict = request.POST.get("verdict")
    allowed = {c.value for c in RelevanceFeedback.Verdict}
    if verdict not in allowed:
        messages.error(request, "Unknown feedback action.")
        return redirect("brief")

    RelevanceFeedback.objects.update_or_create(
        user=request.user,
        article=article,
        defaults={"verdict": verdict},
    )
    labels = {
        RelevanceFeedback.Verdict.RELEVANT: "Marked as relevant",
        RelevanceFeedback.Verdict.NOT_RELEVANT: "Marked as not relevant",
        RelevanceFeedback.Verdict.SKIP: "Skipped",
    }
    messages.success(request, labels[verdict])
    return redirect("brief")


@login_required
def followups(request: HttpRequest) -> HttpResponse:
    questions = next_questions(request.user, limit=5)
    answered = (
        FollowUpAnswer.objects.filter(user=request.user)
        .select_related("question")
        .order_by("-updated_at")
    )
    return render(
        request,
        "news/followups.html",
        {"questions": questions, "answered": answered},
    )


@login_required
def answer_followup(request: HttpRequest, question_id: int) -> HttpResponse:
    question = get_object_or_404(FollowUpQuestion, pk=question_id, is_active=True)
    if request.method == "POST":
        form = FollowUpAnswerForm(request.POST)
        if form.is_valid():
            FollowUpAnswer.objects.update_or_create(
                user=request.user,
                question=question,
                defaults={"answer": form.cleaned_data["answer"]},
            )
            messages.success(request, "Saved — that will shape future filtering.")
            return redirect("followups")
    else:
        existing = FollowUpAnswer.objects.filter(
            user=request.user, question=question
        ).first()
        form = FollowUpAnswerForm(instance=existing)
    return render(
        request,
        "news/answer_followup.html",
        {"question": question, "form": form},
    )
