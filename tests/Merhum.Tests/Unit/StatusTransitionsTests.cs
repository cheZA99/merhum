using MerhumAPI.Common;
using MerhumAPI.Models;

namespace Merhum.Tests.Unit;

public class StatusTransitionsTests
{
    [Theory]
    [InlineData(AppointmentStatus.Scheduled, AppointmentStatus.Held, true)]
    [InlineData(AppointmentStatus.Scheduled, AppointmentStatus.Cancelled, true)]
    [InlineData(AppointmentStatus.Held, AppointmentStatus.Cancelled, false)]
    [InlineData(AppointmentStatus.Cancelled, AppointmentStatus.Scheduled, false)]
    [InlineData(AppointmentStatus.Scheduled, AppointmentStatus.Scheduled, false)]
    public void Appointment_transitions_follow_the_lifecycle(AppointmentStatus from, AppointmentStatus to, bool expected)
    {
        Assert.Equal(expected, StatusTransitions.AppointmentAllows(from, to));
    }

    [Theory]
    [InlineData(ServiceOrderStatus.Ordered, ServiceOrderStatus.InProgress, true)]
    [InlineData(ServiceOrderStatus.Ordered, ServiceOrderStatus.Cancelled, true)]
    [InlineData(ServiceOrderStatus.InProgress, ServiceOrderStatus.Completed, true)]
    [InlineData(ServiceOrderStatus.Ordered, ServiceOrderStatus.Completed, false)]
    [InlineData(ServiceOrderStatus.Completed, ServiceOrderStatus.Cancelled, false)]
    [InlineData(ServiceOrderStatus.Cancelled, ServiceOrderStatus.InProgress, false)]
    public void Service_order_transitions_follow_the_lifecycle(ServiceOrderStatus from, ServiceOrderStatus to, bool expected)
    {
        Assert.Equal(expected, StatusTransitions.ServiceOrderAllows(from, to));
    }

    [Theory]
    [InlineData(1, 2, true)]
    [InlineData(6, 7, true)]
    [InlineData(1, 3, false)]
    [InlineData(3, 2, false)]
    [InlineData(4, 4, false)]
    public void Procedure_moves_exactly_one_phase_forward(int from, int to, bool expected)
    {
        Assert.Equal(expected, StatusTransitions.ProcedureAllows(from, to));
    }
}
